import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:easy_localization/easy_localization.dart';

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

  double _safetyLevel = 3.0;
  bool _isOfflineAvailable = false;

  final MapController _mapController = MapController();
  LatLng _initialCenter = const LatLng(32.885353, 13.180161);

  @override
  void initState() {
    super.initState();
    _getCurrentLocationAndCenterMap();
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    _membersCountController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocationAndCenterMap() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _initialCenter = LatLng(position.latitude, position.longitude);
        });
        _mapController.move(_initialCenter, 13.0);
      }
    } catch (e) {
      print("Could not get location: $e");
    }
  }

  Future<void> _saveTeamAndRoute() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startPoint == null || _endPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('validator_select_map_points'.tr())),
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
      final routeDoc =
          await FirebaseFirestore.instance.collection('evacuation_routes').add({
        'startPoint': GeoPoint(_startPoint!.latitude, _startPoint!.longitude),
        'endPoint': GeoPoint(_endPoint!.latitude, _endPoint!.longitude),
        'safetyLevel': _safetyLevel.toInt(),
        'isOfflineAvailable': _isOfflineAvailable,
        'lastModifiedBy': user.uid,
        'lastModifiedAt': Timestamp.now(),
      });

      await FirebaseFirestore.instance.collection('rescue_teams').add({
        'name': _teamNameController.text.trim(),
        'membersCount': int.tryParse(_membersCountController.text.trim()) ?? 0,
        'assignedRouteId': routeDoc.id,
        'creatorId': user.uid,
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('team_created_successfully'.tr()),
            backgroundColor: Colors.green),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'failed_to_save_team'.tr()} $e')),
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
      appBar: AppBar(title: Text('add_new_team_title'.tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _teamNameController,
                decoration: InputDecoration(labelText: 'team_name_label'.tr()),
                validator: (value) =>
                    value!.isEmpty ? 'validator_enter_team_name'.tr() : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _membersCountController,
                decoration:
                    InputDecoration(labelText: 'members_count_label'.tr()),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty
                    ? 'validator_enter_members_count'.tr()
                    : null,
              ),
              const SizedBox(height: 24),
              Text('define_evacuation_route'.tr(),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Text('map_tap_instruction'.tr(),
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              SizedBox(
                height: 300,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _initialCenter,
                    initialZoom: 13.0,
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
              Text('${'route_safety_level'.tr()} ${_safetyLevel.toInt()}',
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
              SwitchListTile(
                title: Text('make_route_offline'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w500)),
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
                    : Text('save_team_button'.tr(),
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
