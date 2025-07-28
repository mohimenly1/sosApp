import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

class SosConfirmationCard extends StatefulWidget {
  const SosConfirmationCard({super.key});

  @override
  State<SosConfirmationCard> createState() => _SosConfirmationCardState();
}

class _SosConfirmationCardState extends State<SosConfirmationCard> {
  bool _showReportForm = false;
  bool _isLoading = false;
  final _descriptionController = TextEditingController();

  // NEW: State variables for report type and location
  String _reportType = 'text'; // 'text', 'image', 'file', 'voice'
  Position? _currentPosition;
  String _locationMessage = 'Fetching location...';
  File? _imageFile;

  // NEW: Function to get user's current location
  Future<void> _determinePosition() async {
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
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _locationMessage = 'Location captured successfully!';
      });
    } catch (e) {
      setState(() => _locationMessage = 'Failed to get location.');
    }
  }

  // NEW: Function to pick an image from camera or gallery
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

  // Function to handle sending the report to Firestore
  Future<void> _sendReport() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You must be logged in to send a report.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String content = _descriptionController.text.trim();

      // TODO: If reportType is 'image' or 'file', first upload the file to Firebase Storage
      // and get the download URL. The URL will be the 'content'.
      // For now, we'll just save the description.

      final reportData = {
        'userId': user.uid,
        'reportType': _reportType,
        'content': content,
        'location': _currentPosition != null
            ? GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude)
            : null,
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

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send report: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
          'Do you want send\na distress signal?',
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
                _determinePosition(); // Fetch location when user clicks 'Yes'
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

  // UPDATED: Widget for the report submission form with report type options
  Widget _buildReportForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Report type icons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildReportTypeIcon(Icons.text_fields, 'text', 'Text'),
            _buildReportTypeIcon(Icons.camera_alt_outlined, 'image', 'Camera'),
            _buildReportTypeIcon(Icons.attach_file, 'file', 'File'),
            _buildReportTypeIcon(Icons.mic_none, 'voice', 'Voice'),
          ],
        ),
        const SizedBox(height: 20),
        // Description field or image preview
        _reportType == 'image' && _imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(_imageFile!, height: 100, fit: BoxFit.cover),
              )
            : TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  hintText: 'Description (optional)',
                  border: UnderlineInputBorder(),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF0A2342)),
                  ),
                ),
                maxLines: 1,
              ),
        const SizedBox(height: 8),
        // Location status
        Text(
          _locationMessage,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
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

  // Helper widget to build the icons for report types
  Widget _buildReportTypeIcon(IconData icon, String type, String tooltip) {
    bool isSelected = _reportType == type;
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      color: isSelected ? const Color(0xFF0A2342) : Colors.grey,
      iconSize: 30,
      onPressed: () {
        if (type == 'image') {
          _pickImage(ImageSource.camera);
        } else if (type == 'file') {
          // TODO: Implement file picking logic
        } else if (type == 'voice') {
          // TODO: Implement voice recording logic
        } else {
          setState(() => _reportType = type);
        }
      },
    );
  }
}
