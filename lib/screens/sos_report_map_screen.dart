import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

class SosReportMapScreen extends StatefulWidget {
  final Position initialPosition;

  const SosReportMapScreen({super.key, required this.initialPosition});

  @override
  State<SosReportMapScreen> createState() => _SosReportMapScreenState();
}

class _SosReportMapScreenState extends State<SosReportMapScreen> {
  final _descriptionController = TextEditingController();
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();

  late LatLng _reportLocation;
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _reportLocation = LatLng(
        widget.initialPosition.latitude, widget.initialPosition.longitude);
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final fileName = path.basename(image.path);
      final destination = 'sos_images/$fileName';
      final ref = FirebaseStorage.instance.ref(destination);
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      print("Failed to upload image: $e");
      return null;
    }
  }

  Future<void> _sendReport() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await _uploadImage(_imageFile!);
      }

      await FirebaseFirestore.instance.collection('reports').add({
        'userId': user.uid,
        'reportType': imageUrl != null ? 'image' : 'text',
        'content': _descriptionController.text.trim(),
        'imageUrl': imageUrl,
        'location':
            GeoPoint(_reportLocation.latitude, _reportLocation.longitude),
        'timestamp': Timestamp.now(),
        'status': 'pending',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('distress_signal_sent_successfully'.tr()),
            backgroundColor: Colors.green),
      );
      Navigator.of(context).pop(); // Go back from this screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'failed_to_send_report'.tr()}: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('confirm_incident_location'.tr())),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _reportLocation,
              zoom: 15.0,
            ),
            onMapCreated: (GoogleMapController controller) {
              _mapController.complete(controller);
            },
            onTap: (LatLng point) {
              setState(() {
                _reportLocation = point;
              });
            },
            markers: {
              Marker(
                markerId: const MarkerId('reportLocation'),
                position: _reportLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed),
              ),
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Card(
              margin: const EdgeInsets.all(16.0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        hintText: 'description_optional'.tr(),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.camera_alt_outlined),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                    if (_imageFile != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                            '${'image_attached'.tr()} ${path.basename(_imageFile!.path)}',
                            style: const TextStyle(color: Colors.green)),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sendReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text('send_now'.tr(),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
