import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class TeamDetailsScreen extends StatefulWidget {
  final String teamId;

  const TeamDetailsScreen({super.key, required this.teamId});

  @override
  State<TeamDetailsScreen> createState() => _TeamDetailsScreenState();
}

class _TeamDetailsScreenState extends State<TeamDetailsScreen> {
  Map<String, dynamic>? _teamData;
  Map<String, dynamic>? _routeData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // 1. Fetch team data
      final teamDoc = await FirebaseFirestore.instance
          .collection('rescue_teams')
          .doc(widget.teamId)
          .get();
      if (!teamDoc.exists) {
        throw Exception("Team not found");
      }
      final teamData = teamDoc.data()!;

      // 2. Fetch associated route data
      final routeId = teamData['assignedRouteId'];
      final routeDoc = await FirebaseFirestore.instance
          .collection('evacuation_routes')
          .doc(routeId)
          .get();
      if (!routeDoc.exists) {
        throw Exception("Route not found");
      }

      setState(() {
        _teamData = teamData;
        _routeData = routeDoc.data()!;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load details: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_teamData?['name'] ?? 'Team Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _teamData == null || _routeData == null
              ? const Center(child: Text('Could not load team data.'))
              : _buildDetailsView(),
    );
  }

  Widget _buildDetailsView() {
    final startPointGeo = _routeData!['startPoint'] as GeoPoint;
    final endPointGeo = _routeData!['endPoint'] as GeoPoint;
    final startPoint = LatLng(startPointGeo.latitude, startPointGeo.longitude);
    final endPoint = LatLng(endPointGeo.latitude, endPointGeo.longitude);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 300,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: startPoint,
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [startPoint, endPoint],
                      strokeWidth: 5.0,
                      color: Colors.blue,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: startPoint,
                      width: 80,
                      height: 80,
                      child: const Column(children: [
                        Icon(Icons.location_on, color: Colors.green, size: 40),
                        Text('Start')
                      ]),
                    ),
                    Marker(
                      point: endPoint,
                      width: 80,
                      height: 80,
                      child: const Column(children: [
                        Icon(Icons.location_on, color: Colors.red, size: 40),
                        Text('End')
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(Icons.group, 'Team Name', _teamData!['name']),
                _buildDetailRow(Icons.person_add, 'Member Count',
                    _teamData!['membersCount'].toString()),
                const Divider(height: 32),
                const Text('Route Information',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.security, 'Safety Level',
                    _routeData!['safetyLevel'].toString()),
                _buildDetailRow(Icons.wifi_off, 'Offline Available',
                    _routeData!['isOfflineAvailable'] ? 'Yes' : 'No'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Text('$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Flexible(child: Text(value)),
        ],
      ),
    );
  }
}
