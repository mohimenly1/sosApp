import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  void initState() {
    super.initState();
    _loadMedicalData();
  }

  @override
  void dispose() {
    _bloodTypeController.dispose();
    _diseasesController.dispose();
    _allergiesController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  Future<void> _loadMedicalData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && userDoc.data()!['medicalFileId'] != null) {
        final medicalId = userDoc.data()!['medicalFileId'];
        setState(() => _medicalFileId = medicalId);

        final medicalDoc = await FirebaseFirestore.instance
            .collection('medical_files')
            .doc(medicalId)
            .get();

        if (medicalDoc.exists) {
          final data = medicalDoc.data()!;
          _bloodTypeController.text = data['bloodType'] ?? '';
          _diseasesController.text = data['chronicDiseases'] ?? '';
          _allergiesController.text = data['allergies'] ?? '';
          _emergencyContactController.text = data['emergencyContact'] ?? '';
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load medical data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveMedicalFile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final medicalData = {
      'bloodType': _bloodTypeController.text.trim(),
      'chronicDiseases': _diseasesController.text.trim(),
      'allergies': _allergiesController.text.trim(),
      'emergencyContact': _emergencyContactController.text.trim(),
      'lastUpdated': Timestamp.now(),
      'ownerId': user.uid,
    };

    try {
      if (_medicalFileId == null) {
        final newMedicalDoc = await FirebaseFirestore.instance
            .collection('medical_files')
            .add(medicalData);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'medicalFileId': newMedicalDoc.id,
        });
      } else {
        await FirebaseFirestore.instance
            .collection('medical_files')
            .doc(_medicalFileId)
            .update(medicalData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Medical file saved successfully!'),
            backgroundColor: Colors.green),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Medical File"),
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
                    const Text(
                      "Your medical information is crucial in an emergency. Please keep it updated.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _bloodTypeController,
                      decoration: const InputDecoration(
                          labelText: "Blood Type (e.g., O+)"),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _diseasesController,
                      decoration:
                          const InputDecoration(labelText: "Chronic Diseases"),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _allergiesController,
                      decoration: const InputDecoration(labelText: "Allergies"),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emergencyContactController,
                      decoration: const InputDecoration(
                          labelText: "Emergency Contact (Name & Phone)"),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _saveMedicalFile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A2342),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text("Save Information",
                          style: TextStyle(
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
