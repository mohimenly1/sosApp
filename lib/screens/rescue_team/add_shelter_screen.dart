import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

class AddShelterScreen extends StatefulWidget {
  const AddShelterScreen({super.key});

  @override
  State<AddShelterScreen> createState() => _AddShelterScreenState();
}

class _AddShelterScreenState extends State<AddShelterScreen> {
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  Set<Marker> _markers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExistingShelters();
  }

  Future<void> _loadExistingShelters() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('shelters').get();
    final markers = snapshot.docs.map((doc) {
      final data = doc.data();
      final location = data['location'] as GeoPoint;
      return Marker(
        markerId: MarkerId(doc.id),
        position: LatLng(location.latitude, location.longitude),
        infoWindow: InfoWindow(title: data['name']),
        icon: _getMarkerIcon(data['type']),
      );
    }).toSet();

    if (mounted) {
      setState(() {
        _markers = markers;
        _isLoading = false;
      });
    }
  }

  BitmapDescriptor _getMarkerIcon(String type) {
    switch (type) {
      case 'Hospital':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      case 'Clinic':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'Mobile Clinic':
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  void _onMapTap(LatLng position) {
    showDialog(
      context: context,
      builder: (context) => _AddShelterDialog(
        position: position,
        onSave: (name, type) {
          _addShelterToFirestore(name, type, position);
        },
      ),
    );
  }

  Future<void> _addShelterToFirestore(
      String name, String type, LatLng position) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('shelters').add({
        'name': name,
        'type': type,
        'location': GeoPoint(position.latitude, position.longitude),
        'createdBy': user.uid,
        'createdAt': Timestamp.now(),
      });
      _loadExistingShelters();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'failed_to_add_shelter'.tr()} $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('add_shelters_title'.tr())),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(32.885353, 13.180161), // Tripoli
                zoom: 12,
              ),
              onMapCreated: (controller) => _mapController.complete(controller),
              onTap: _onMapTap,
              markers: _markers,
            ),
    );
  }
}

class _AddShelterDialog extends StatefulWidget {
  final LatLng position;
  final Function(String name, String type) onSave;

  const _AddShelterDialog({required this.position, required this.onSave});

  @override
  State<_AddShelterDialog> createState() => _AddShelterDialogState();
}

class _AddShelterDialogState extends State<_AddShelterDialog> {
  final _nameController = TextEditingController();
  // Keys for logic remain in English
  String _selectedType = 'Hospital';
  final List<String> _shelterTypes = ['Hospital', 'Clinic', 'Mobile Clinic'];

  // Map English keys to translation keys
  final Map<String, String> _translationKeys = {
    'Hospital': 'hospital',
    'Clinic': 'clinic',
    'Mobile Clinic': 'mobile_clinic',
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('add_shelter_details_title'.tr()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'shelter_name_label'.tr()),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedType,
            items: _shelterTypes
                .map((type) => DropdownMenuItem(
                    value: type,
                    child: Text((_translationKeys[type] ?? type).tr())))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedType = value);
            },
            decoration: InputDecoration(labelText: 'shelter_type_label'.tr()),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('cancel'.tr())),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty) {
              widget.onSave(_nameController.text, _selectedType);
              Navigator.of(context).pop();
            }
          },
          child: Text('save'.tr()),
        ),
      ],
    );
  }
}
