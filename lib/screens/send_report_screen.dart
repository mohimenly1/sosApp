import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:path/path.dart' as path;
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class SendReportScreen extends StatefulWidget {
  const SendReportScreen({super.key});

  @override
  State<SendReportScreen> createState() => _SendReportScreenState();
}

class _SendReportScreenState extends State<SendReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final MapController _mapController = MapController();

  String? _selectedReportType;
  File? _imageFile;
  Position? _currentPosition;
  bool _isLoading = false;
  String _statusMessage = "Detecting location...";

  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _audioPath;
  bool _isRecording = false;

  final List<String> _reportTypes = [
    'Medical',
    'Fire',
    'Accident',
    'Theft',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      print('AudioPlayer state: $state');
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _statusMessage = "Location Detected";
        });
        _mapController.move(
            LatLng(position.latitude, position.longitude), 15.0);
      }
    } catch (e) {
      if (mounted) setState(() => _statusMessage = '');
    }
  }

  // MODIFIED: This function now opens the camera directly.
  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _deleteAudio(); // Clear any existing audio recording
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final tempDir = await getTemporaryDirectory();
      final filePath = path.join(
          tempDir.path, '${DateTime.now().millisecondsSinceEpoch}.m4a');

      await _audioRecorder.start(const RecordConfig(), path: filePath);

      setState(() {
        _isRecording = true;
        _deleteImage();
      });
    }
  }

  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    if (path != null) {
      setState(() {
        _isRecording = false;
        _audioPath = path;
      });
    }
  }

  Future<void> _playRecording() async {
    if (_audioPath != null) {
      try {
        await _audioPlayer.stop();
        await _audioPlayer.play(DeviceFileSource(_audioPath!));
      } catch (e) {
        print("Error playing audio: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not play the audio file.')),
        );
      }
    }
  }

  void _deleteAudio() {
    _audioPlayer.stop();
    if (_audioPath != null) {
      final file = File(_audioPath!);
      if (file.existsSync()) {
        file.delete();
      }
    }
    setState(() => _audioPath = null);
  }

  void _deleteImage() {
    setState(() => _imageFile = null);
  }

  Future<String?> _uploadFile(File file, String folder) async {
    try {
      final fileName = path.basename(file.path);
      final destination = '$folder/$fileName';
      final ref = FirebaseStorage.instance.ref(destination);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      print("Failed to upload file: $e");
      return null;
    }
  }

  Future<void> _sendReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Waiting for location...')));
      return;
    }

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      String? imageUrl;
      String? audioUrl;
      String reportType = 'text';

      if (_imageFile != null) {
        imageUrl = await _uploadFile(_imageFile!, 'report_images');
        if (imageUrl == null) {
          throw Exception(
              "Image upload failed. Please check your connection or storage rules.");
        }
      }
      if (_audioPath != null) {
        audioUrl = await _uploadFile(File(_audioPath!), 'report_audio');
        if (audioUrl == null) {
          throw Exception(
              "Audio upload failed. Please check your connection or storage rules.");
        }
      }

      if (audioUrl != null) {
        reportType = 'audio';
      } else if (imageUrl != null) {
        reportType = 'image';
      }

      final reportData = {
        'userId': user.uid,
        'reportType': reportType,
        'disasterType': _selectedReportType,
        'content': _descriptionController.text.trim(),
        'imageUrl': imageUrl,
        'audioUrl': audioUrl,
        'location':
            GeoPoint(_currentPosition!.latitude, _currentPosition!.longitude),
        'timestamp': Timestamp.now(),
        'status': 'pending',
      };

      await FirebaseFirestore.instance.collection('reports').add(reportData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Report sent successfully!'),
            backgroundColor: Colors.green),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Failed to send report: ${e.toString().replaceFirst("Exception: ", "")}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDescriptionEnabled = _audioPath == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Report Type',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedReportType,
                decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
                hint: const Text('Select a report type'),
                items: _reportTypes
                    .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedReportType = value),
                validator: (value) =>
                    value == null ? 'Please select a type' : null,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _descriptionController,
                enabled: isDescriptionEnabled,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  fillColor: isDescriptionEnabled ? null : Colors.grey.shade200,
                  filled: !isDescriptionEnabled,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              _buildVoiceRecorderUI(),
              const SizedBox(height: 24),
              const Text('Add Image',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12)),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_imageFile!, fit: BoxFit.cover))
                      : const Center(
                          child: Icon(Icons.add_a_photo_outlined,
                              size: 50, color: Colors.grey)),
                ),
              ),
              const SizedBox(height: 24),
              Text(_statusMessage,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: _currentPosition == null
                    ? const Center(child: CircularProgressIndicator())
                    : FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: LatLng(_currentPosition!.latitude,
                              _currentPosition!.longitude),
                          initialZoom: 15.0,
                        ),
                        children: [
                          TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                          MarkerLayer(markers: [
                            Marker(
                              point: LatLng(_currentPosition!.latitude,
                                  _currentPosition!.longitude),
                              child: const Icon(Icons.location_on,
                                  color: Colors.red, size: 40),
                            ),
                          ]),
                        ],
                      ),
              ),
              const SizedBox(height: 32),
              // MODIFIED: The button is now wider and centered.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Send Report',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceRecorderUI() {
    if (_isRecording) {
      return Card(
        color: Colors.red.shade100,
        child: ListTile(
          leading: const Icon(Icons.mic, color: Colors.red),
          title: const Text('Recording...'),
          trailing: IconButton(
            icon: const Icon(Icons.stop, color: Colors.red),
            onPressed: _stopRecording,
          ),
        ),
      );
    }

    if (_audioPath != null) {
      return Card(
        color: Colors.blue.shade50,
        child: ListTile(
          leading: const Icon(Icons.audiotrack, color: Colors.blue),
          title: const Text('Voice Note Ready'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.play_arrow, color: Colors.blue),
                onPressed: _playRecording,
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.grey),
                onPressed: _deleteAudio,
              ),
            ],
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      icon: const Icon(Icons.mic_none, color: Colors.white),
      label: const Text('Record Voice Note',
          style: TextStyle(color: Colors.white)),
      onPressed: _startRecording,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0A2342),
      ),
    );
  }
}
