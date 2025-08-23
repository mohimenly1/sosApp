import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

class SheltersMapScreen extends StatefulWidget {
  const SheltersMapScreen({super.key});

  @override
  State<SheltersMapScreen> createState() => _SheltersMapScreenState();
}

class _SheltersMapScreenState extends State<SheltersMapScreen> {
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();

  final Map<String, Marker> _allMarkers = {};
  Set<Marker> _filteredMarkers = {};
  bool _isLoading = true;

  // The keys remain in English for logic, but the labels will be translated.
  final Map<String, bool> _filters = {
    'Hospital': true,
    'Clinic': true,
    'Mobile Clinic': true,
  };

  // Map English keys to translation keys
  final Map<String, String> _translationKeys = {
    'Hospital': 'hospital',
    'Clinic': 'clinic',
    'Mobile Clinic': 'mobile_clinic',
  };

  @override
  void initState() {
    super.initState();
    _loadShelters();
  }

  Future<void> _loadShelters() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('shelters').get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final location = data['location'] as GeoPoint;
      final type = data['type'] as String;

      final marker = Marker(
        markerId: MarkerId(doc.id),
        position: LatLng(location.latitude, location.longitude),
        infoWindow: InfoWindow(title: data['name'], snippet: type),
        icon: _getMarkerIcon(type),
      );
      _allMarkers[doc.id] = marker;
    }
    _applyFilters();
    if (mounted) {
      setState(() => _isLoading = false);
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

  void _applyFilters() {
    final Set<Marker> tempMarkers = {};
    _allMarkers.forEach((id, marker) {
      final type = marker.infoWindow.snippet!;
      if (_filters[type] == true) {
        tempMarkers.add(marker);
      }
    });
    if (mounted) {
      setState(() {
        _filteredMarkers = tempMarkers;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('shelters_medical_points'.tr())),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(32.885353, 13.180161), // Tripoli
                    zoom: 12,
                  ),
                  onMapCreated: (controller) =>
                      _mapController.complete(controller),
                  markers: _filteredMarkers,
                ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _filters.keys.map((type) {
                    // Use the translation key for the label
                    final translationKey = _translationKeys[type] ?? type;
                    return FilterChip(
                      label: Text(translationKey.tr()),
                      selected: _filters[type]!,
                      onSelected: (bool selected) {
                        setState(() {
                          _filters[type] = selected;
                        });
                        _applyFilters();
                      },
                      selectedColor: Colors.blue.shade100,
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
