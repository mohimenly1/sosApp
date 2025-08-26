import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:easy_localization/easy_localization.dart';

class SendAlertScreen extends StatefulWidget {
  const SendAlertScreen({super.key});

  @override
  State<SendAlertScreen> createState() => _SendAlertScreenState();
}

class _SendAlertScreenState extends State<SendAlertScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  String? _selectedDisasterType;
  LatLng? _affectedLocation;

  // Keys for logic remain in English
  final List<String> _disasterTypes = [
    'disaster_type_earthquake',
    'disaster_type_flood',
    'disaster_type_fire',
    'disaster_type_hurricane',
    'disaster_type_other'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _sendAlert() async {
    if (!_formKey.currentState!.validate()) return;
    if (_affectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('validator_select_location'.tr())),
      );
      return;
    }

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('alerts').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'disasterType': _selectedDisasterType, // Storing the key
        'location':
            GeoPoint(_affectedLocation!.latitude, _affectedLocation!.longitude),
        'timestamp': Timestamp.now(),
        'createdBy': user.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('alert_sent_successfully'.tr()),
            backgroundColor: Colors.green),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'failed_to_send_alert'.tr()} $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('send_emergency_alert_title'.tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration:
                    InputDecoration(labelText: 'alert_title_label'.tr()),
                validator: (value) =>
                    value!.isEmpty ? 'validator_enter_title'.tr() : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration:
                    InputDecoration(labelText: 'description_label'.tr()),
                maxLines: 4,
                validator: (value) =>
                    value!.isEmpty ? 'validator_enter_description'.tr() : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDisasterType,
                decoration:
                    InputDecoration(labelText: 'disaster_type_label'.tr()),
                items: _disasterTypes.map((String typeKey) {
                  return DropdownMenuItem<String>(
                      value: typeKey, child: Text(typeKey.tr()));
                }).toList(),
                onChanged: (newValue) {
                  setState(() => _selectedDisasterType = newValue);
                },
                validator: (value) =>
                    value == null ? 'validator_select_type'.tr() : null,
              ),
              const SizedBox(height: 24),
              Text('pinpoint_location_label'.tr(),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 300,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(32.885353, 13.180161),
                    initialZoom: 9.2,
                    onTap: (tapPosition, point) =>
                        setState(() => _affectedLocation = point),
                  ),
                  children: [
                    TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                    if (_affectedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _affectedLocation!,
                            width: 80,
                            height: 80,
                            child: const Icon(Icons.location_on,
                                color: Colors.red, size: 40),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _sendAlert,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('send_alert_now_button'.tr(),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
