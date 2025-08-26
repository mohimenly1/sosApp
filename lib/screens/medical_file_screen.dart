import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_helper.dart';
import 'package:easy_localization/easy_localization.dart';

class MedicalFileScreen extends StatefulWidget {
  const MedicalFileScreen({super.key});

  @override
  State<MedicalFileScreen> createState() => _MedicalFileScreenState();
}

class _MedicalFileScreenState extends State<MedicalFileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  String? _medicalFileId;

  final _bloodTypeController = TextEditingController();
  final _diseasesController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _emergencyContactController = TextEditingController();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _initAndSyncData();
  }

  @override
  void dispose() {
    _bloodTypeController.dispose();
    _diseasesController.dispose();
    _allergiesController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  Future<void> _initAndSyncData() async {
    await _loadLocalData();
    _syncFirestoreData();
  }

  Future<void> _loadLocalData() async {
    if (_currentUserId == null) {
      setState(() => _isLoading = false);
      return;
    }
    final localData = await _dbHelper.getMedicalFileByOwnerId(_currentUserId!);
    if (mounted && localData != null) {
      setState(() {
        _medicalFileId = localData['id'];
        _bloodTypeController.text = localData['bloodType'] ?? '';
        _diseasesController.text = localData['chronicDiseases'] ?? '';
        _allergiesController.text = localData['allergies'] ?? '';
        _emergencyContactController.text = localData['emergencyContact'] ?? '';
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _syncFirestoreData() async {
    if (_currentUserId == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .get();
      final medicalId = userDoc.data()?['medicalFileId'];

      if (medicalId != null) {
        final medicalDoc = await FirebaseFirestore.instance
            .collection('medical_files')
            .doc(medicalId)
            .get();
        if (medicalDoc.exists) {
          final data = medicalDoc.data()!;
          final lastUpdated = (data['lastUpdated'] as Timestamp).toDate();

          final fileForDb = {
            'id': medicalDoc.id,
            'ownerId': _currentUserId,
            'bloodType': data['bloodType'],
            'chronicDiseases': data['chronicDiseases'],
            'allergies': data['allergies'],
            'emergencyContact': data['emergencyContact'],
            'lastUpdated': lastUpdated.toIso8601String(),
          };

          await _dbHelper.insertMedicalFile(fileForDb);
          await _loadLocalData();
        }
      }
    } catch (e) {
      print("Failed to sync medical file: $e");
    }
  }

  Future<void> _saveMedicalFile() async {
    if (!_formKey.currentState!.validate() || _currentUserId == null) return;

    setState(() => _isLoading = true);

    final medicalData = {
      'bloodType': _bloodTypeController.text.trim(),
      'chronicDiseases': _diseasesController.text.trim(),
      'allergies': _allergiesController.text.trim(),
      'emergencyContact': _emergencyContactController.text.trim(),
      'lastUpdated': Timestamp.now(),
      'ownerId': _currentUserId,
    };

    try {
      if (_medicalFileId == null) {
        final newMedicalDoc = await FirebaseFirestore.instance
            .collection('medical_files')
            .add(medicalData);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserId)
            .update({
          'medicalFileId': newMedicalDoc.id,
        });
        _medicalFileId = newMedicalDoc.id;
      } else {
        await FirebaseFirestore.instance
            .collection('medical_files')
            .doc(_medicalFileId)
            .update(medicalData);
      }

      final lastUpdated = (medicalData['lastUpdated'] as Timestamp).toDate();
      final fileForDb = {
        'id': _medicalFileId,
        'ownerId': _currentUserId,
        ...medicalData,
        'lastUpdated': lastUpdated.toIso8601String(),
      };
      await _dbHelper.insertMedicalFile(fileForDb as Map<String, dynamic>);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("medical_file_saved_successfully".tr()),
            backgroundColor: Colors.green),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${"failed_to_save_data".tr()} $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("medical_file_title".tr()),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.medical_services,
                        size: 60, color: Color(0xFF0A2342)),
                    const SizedBox(height: 16),
                    Text(
                      "medical_info_prompt".tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _bloodTypeController,
                      decoration:
                          InputDecoration(labelText: "blood_type_label".tr()),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _diseasesController,
                      decoration: InputDecoration(
                          labelText: "chronic_diseases_label".tr()),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _allergiesController,
                      decoration:
                          InputDecoration(labelText: "allergies_label".tr()),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emergencyContactController,
                      decoration: InputDecoration(
                          labelText: "emergency_contact_label".tr()),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveMedicalFile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A2342),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text("save_information_button".tr(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
