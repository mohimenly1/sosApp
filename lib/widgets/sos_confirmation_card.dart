import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart'; // Import flutter_map
import 'package:latlong2/latlong.dart'; // Import latlong2

class SosConfirmationCard extends StatefulWidget {
  const SosConfirmationCard({super.key});

  @override
  State<SosConfirmationCard> createState() => _SosConfirmationCardState();
}

class _SosConfirmationCardState extends State<SosConfirmationCard> {
  bool _showReportForm = false;
  bool _isLoading = false;
  final _descriptionController = TextEditingController();

  String _reportType = 'text';
  Position? _currentPosition;
  String _locationMessage = 'Determining location...';
  File? _imageFile;
  final MapController _mapController = MapController();

  Future<void> _determinePosition() async {
    // ... (Location permission logic remains the same)
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _locationMessage = 'Location services are disabled.');
      return;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _locationMessage = 'Location permissions are denied.');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() =>
          _locationMessage = 'Location permissions are permanently denied.');
      return;
    }

    try {
      setState(() => _locationMessage = 'Fetching location...');
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _locationMessage = 'Location captured. Tap map to adjust.';

        _mapController.move(
            LatLng(position.latitude, position.longitude), 15.0);
      });
    } catch (e) {
      setState(() => _locationMessage = 'Failed to get location.');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _reportType = 'image';
        _descriptionController.text = 'Image attached.';
      });
    }
  }

  Future<void> _sendReport() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location is required to send a report.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String content = _descriptionController.text.trim();
      final reportData = {
        'userId': user.uid,
        'reportType': _reportType,
        'content': content,
        'location':
            GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude),
        'timestamp': Timestamp.now(),
        'status': 'pending',
      };
      await FirebaseFirestore.instance.collection('reports').add(reportData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Distress signal sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send report: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 300),
        crossFadeState: _showReportForm
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
        firstChild: _buildConfirmationPrompt(),
        secondChild: _buildReportForm(),
      ),
    );
  }

  Widget _buildConfirmationPrompt() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Do you want to send\na distress signal?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0A2342),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() => _showReportForm = true);
                _determinePosition();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A2342),
                minimumSize: const Size(100, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Yes',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A2342),
                minimumSize: const Size(100, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('No',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Confirm Incident Location",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        // NEW: Interactive Map Widget
        SizedBox(
          height: 200,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition != null
                  ? LatLng(
                      _currentPosition!.latitude, _currentPosition!.longitude)
                  : LatLng(32.885353, 13.180161), // Default to Tripoli
              initialZoom: 15.0,
              onTap: (tapPosition, point) {
                setState(() {
                  // Update the position when the user taps the map
                  _currentPosition = Position(
                      latitude: point.latitude,
                      longitude: point.longitude,
                      timestamp: DateTime.now(),
                      accuracy: 0,
                      altitude: 0,
                      altitudeAccuracy: 0,
                      heading: 0,
                      headingAccuracy: 0,
                      speed: 0,
                      speedAccuracy: 0);
                  _locationMessage = 'Location manually adjusted.';
                });
              },
            ),
            children: [
              TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(_currentPosition!.latitude,
                          _currentPosition!.longitude),
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
        const SizedBox(height: 8),
        Text(_locationMessage,
            style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 16),
        TextField(
          controller: _descriptionController,
          decoration: InputDecoration(
            hintText: 'Description (optional)',
            border: const UnderlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.camera_alt_outlined),
              onPressed: () => _pickImage(ImageSource.camera),
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[700],
            minimumSize: const Size(double.infinity, 50),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Send Now',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
        ),
        TextButton(
          onPressed: () => setState(() => _showReportForm = false),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        )
      ],
    );
  }
}
