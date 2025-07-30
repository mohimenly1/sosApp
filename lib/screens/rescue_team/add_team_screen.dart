import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AddTeamScreen extends StatefulWidget {
  const AddTeamScreen({super.key});

  @override
  State<AddTeamScreen> createState() => _AddTeamScreenState();
}

class _AddTeamScreenState extends State<AddTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teamNameController = TextEditingController();
  final _membersCountController = TextEditingController();
  bool _isLoading = false;

  LatLng? _startPoint;
  LatLng? _endPoint;

  // NEW: State variables for the new fields
  double _safetyLevel = 3.0; // Default safety level (1 to 5)
  bool _isOfflineAvailable = false;

  Future<void> _saveTeamAndRoute() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startPoint == null || _endPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a start and end point on the map.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Create the evacuation route document first, now with the new data
      final routeDoc =
          await FirebaseFirestore.instance.collection('evacuation_routes').add({
        'startPoint': GeoPoint(_startPoint!.latitude, _startPoint!.longitude),
        'endPoint': GeoPoint(_endPoint!.latitude, _endPoint!.longitude),
        'safetyLevel': _safetyLevel.toInt(), // Using the value from the slider
        'isOfflineAvailable':
            _isOfflineAvailable, // Using the value from the switch
        'lastModifiedBy': user.uid,
        'lastModifiedAt': Timestamp.now(),
      });

      // 2. Create the rescue team document and link it to the route
      await FirebaseFirestore.instance.collection('rescue_teams').add({
        'name': _teamNameController.text.trim(),
        'membersCount': int.tryParse(_membersCountController.text.trim()) ?? 0,
        'assignedRouteId': routeDoc.id,
        'creatorId': user.uid,
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Team and route created successfully!'),
            backgroundColor: Colors.green),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save data: $e')),
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
      appBar: AppBar(title: const Text('Add New Team')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _teamNameController,
                decoration: const InputDecoration(labelText: 'Team Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a team name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _membersCountController,
                decoration:
                    const InputDecoration(labelText: 'Number of Members'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty
                    ? 'Please enter the number of members'
                    : null,
              ),
              const SizedBox(height: 24),
              const Text('Define Evacuation Route',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Text('Tap on the map to set Start (S) and End (E) points.',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              SizedBox(
                height: 300,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter:
                        LatLng(32.885353, 13.180161), // Tripoli, Libya
                    initialZoom: 9.2,
                    onTap: (tapPosition, point) {
                      setState(() {
                        if (_startPoint == null || _endPoint != null) {
                          _startPoint = point;
                          _endPoint = null;
                        } else {
                          _endPoint = point;
                        }
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    ),
                    MarkerLayer(
                      markers: [
                        if (_startPoint != null)
                          Marker(
                            point: _startPoint!,
                            width: 80,
                            height: 80,
                            child: const Column(children: [
                              Icon(Icons.location_on,
                                  color: Colors.green, size: 40),
                              Text('S')
                            ]),
                          ),
                        if (_endPoint != null)
                          Marker(
                            point: _endPoint!,
                            width: 80,
                            height: 80,
                            child: const Column(children: [
                              Icon(Icons.location_on,
                                  color: Colors.red, size: 40),
                              Text('E')
                            ]),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // NEW: UI for Safety Level
              Text('Route Safety Level: ${_safetyLevel.toInt()}',
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              Slider(
                value: _safetyLevel,
                min: 1,
                max: 5,
                divisions: 4,
                label: _safetyLevel.round().toString(),
                onChanged: (double value) {
                  setState(() {
                    _safetyLevel = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              // NEW: UI for Offline Availability
              SwitchListTile(
                title: const Text('Make route available offline?',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                value: _isOfflineAvailable,
                onChanged: (bool value) {
                  setState(() {
                    _isOfflineAvailable = value;
                  });
                },
                secondary: const Icon(Icons.signal_wifi_off_outlined),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveTeamAndRoute,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A2342),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Team',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
