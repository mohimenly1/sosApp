import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/database_helper.dart'; // Import the database helper

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
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadDataFromDb();
  }

  // This function now loads all data from the local SQLite database
  Future<void> _loadDataFromDb() async {
    try {
      // 1. Fetch team data from local DB
      final teamData = await _dbHelper.getTeamById(widget.teamId);
      if (teamData == null) throw Exception("Team not found in local DB");

      // 2. Fetch associated route data from local DB
      final routeId = teamData['assignedRouteId'];
      final routeData = await _dbHelper.getRouteById(routeId);
      if (routeData == null) throw Exception("Route not found in local DB");

      setState(() {
        _teamData = teamData;
        _routeData = routeData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to load details from local storage: $e')),
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
    // Read coordinates from the local data
    final startPoint =
        LatLng(_routeData!['startPoint_lat'], _routeData!['startPoint_lon']);
    final endPoint =
        LatLng(_routeData!['endPoint_lat'], _routeData!['endPoint_lon']);

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
                // Read boolean from integer (0 or 1)
                _buildDetailRow(Icons.wifi_off, 'Offline Available',
                    _routeData!['isOfflineAvailable'] == 1 ? 'Yes' : 'No'),
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
