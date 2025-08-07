import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:google_maps_flutter/google_maps_flutter.dart'; // 1. Import Google Maps

class SosReportSheet extends StatefulWidget {
  final Position initialPosition;

  const SosReportSheet({super.key, required this.initialPosition});

  @override
  State<SosReportSheet> createState() => _SosReportSheetState();
}

class _SosReportSheetState extends State<SosReportSheet> {
  final _descriptionController = TextEditingController();
  // 2. Use a Completer for the GoogleMapController
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();

  late LatLng _reportLocation;
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 3. Use the LatLng from the google_maps_flutter package
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
        const SnackBar(
            content: Text('Distress signal sent successfully!'),
            backgroundColor: Colors.green),
      );
      Navigator.of(context).pop(); // Close the bottom sheet
      Navigator.of(context).pop(); // Go back from the SOS screen
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to send report: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
              child: Text("Confirm Incident Location",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          const SizedBox(height: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              // 4. Replace FlutterMap with GoogleMap
              child: GoogleMap(
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
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              hintText: 'Description (optional)',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.camera_alt_outlined),
                onPressed: _pickImage,
              ),
            ),
          ),
          if (_imageFile != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text('Image attached: ${path.basename(_imageFile!.path)}',
                  style: const TextStyle(color: Colors.green)),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _sendReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Send Now',
                      style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}
