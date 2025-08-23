import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/route_info_sheet.dart';

class UserMapScreen extends StatefulWidget {
  const UserMapScreen({super.key});

  @override
  State<UserMapScreen> createState() => _UserMapScreenState();
}

class _UserMapScreenState extends State<UserMapScreen> {
  Position? _currentPosition;
  List<DocumentSnapshot> _nearbyRoutes = [];
  bool _isLoading = true;
  String _statusMessage = "Fetching your location...";

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  Future<void> _initMap() async {
    await _determinePosition();
    if (_currentPosition != null) {
      await _fetchNearbyRoutes();
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _statusMessage = 'Location services are disabled.');
      return;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _statusMessage = 'Location permissions are denied.');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() =>
          _statusMessage = 'Location permissions are permanently denied.');
      return;
    }
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _statusMessage = "Finding nearby safe routes...";
      });
    } catch (e) {
      setState(() => _statusMessage = 'Failed to get location.');
    }
  }

  Future<void> _fetchNearbyRoutes() async {
    if (_currentPosition == null) return;

    final routesSnapshot =
        await FirebaseFirestore.instance.collection('evacuation_routes').get();
    final allRoutes = routesSnapshot.docs;
    final nearby = <DocumentSnapshot>[];

    for (var routeDoc in allRoutes) {
      final routeData = routeDoc.data();
      final startPoint = routeData['startPoint'] as GeoPoint;

      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        startPoint.latitude,
        startPoint.longitude,
      );

      if (distance <= 10000) {
        // 10km radius
        nearby.add(routeDoc);
      }
    }

    setState(() {
      _nearbyRoutes = nearby;
      _statusMessage = nearby.isEmpty
          ? "No safe routes found nearby."
          : "Displaying nearby routes.";
    });
  }

  void _showRouteInfo(DocumentSnapshot routeDoc) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return RouteInfoSheet(routeDoc: routeDoc);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Prepare markers for routes
    final List<Marker> routeMarkers = _nearbyRoutes.expand((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final start = data['startPoint'] as GeoPoint;
      final end = data['endPoint'] as GeoPoint;
      return [
        Marker(
          point: LatLng(start.latitude, start.longitude),
          width: 80,
          height: 80,
          child: GestureDetector(
            onTap: () => _showRouteInfo(doc),
            child: const Column(children: [
              Icon(Icons.location_on, color: Colors.green, size: 40),
              Text('Start')
            ]),
          ),
        ),
        Marker(
          point: LatLng(end.latitude, end.longitude),
          width: 80,
          height: 80,
          child: GestureDetector(
            onTap: () => _showRouteInfo(doc),
            child: const Column(children: [
              Icon(Icons.flag, color: Colors.green, size: 40),
              Text('End')
            ]),
          ),
        ),
      ];
    }).toList();

    // Add user's location marker
    if (_currentPosition != null) {
      routeMarkers.add(
        Marker(
          point:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          width: 80,
          height: 80,
          child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Safe Routes')),
      body: _isLoading
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(_statusMessage)
            ]))
          : FlutterMap(
              options: MapOptions(
                initialCenter: _currentPosition != null
                    ? LatLng(
                        _currentPosition!.latitude, _currentPosition!.longitude)
                    : LatLng(32.885353, 13.180161),
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                PolylineLayer(
                  polylines: _nearbyRoutes.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final start = data['startPoint'] as GeoPoint;
                    final end = data['endPoint'] as GeoPoint;
                    return Polyline(
                      points: [
                        LatLng(start.latitude, start.longitude),
                        LatLng(end.latitude, end.longitude)
                      ],
                      strokeWidth: 5.0,
                      color: Colors.green.withOpacity(0.8),
                    );
                  }).toList(),
                ),
                // THE FIX: Use a single MarkerLayer for all markers
                MarkerLayer(markers: routeMarkers),
              ],
            ),
    );
  }
}
