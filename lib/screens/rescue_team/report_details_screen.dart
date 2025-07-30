import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:resq_track4/screens/rescue_team/active_reports_screen.dart';

class ReportDetailsScreen extends StatefulWidget {
  final String reportId;
  const ReportDetailsScreen({super.key, required this.reportId});

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Distress Signal Details')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('reports')
            .doc(widget.reportId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Report not found.'));
          }

          final reportData = snapshot.data!.data() as Map<String, dynamic>;
          final location = reportData['location'] as GeoPoint;
          final reportLocation = LatLng(location.latitude, location.longitude);
          final timestamp = (reportData['timestamp'] as Timestamp).toDate();
          final formattedDate = DateFormat.yMMMd().add_jm().format(timestamp);

          return Column(
            children: [
              Expanded(
                flex: 3,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: reportLocation,
                    initialZoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: reportLocation,
                          width: 80,
                          height: 80,
                          child: const Icon(Icons.location_on,
                              color: Colors.red, size: 50),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: [
                      _buildDetailRow(Icons.person, 'User',
                          UserInfoWidget(userId: reportData['userId'])),
                      _buildDetailRow(Icons.description, 'Description',
                          Text(reportData['content'])),
                      _buildDetailRow(Icons.category, 'Report Type',
                          Text(reportData['reportType'])),
                      _buildDetailRow(Icons.timer, 'Time', Text(formattedDate)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.route_outlined,
                            color: Colors.white),
                        label: const Text('Share Safe Route',
                            style: TextStyle(color: Colors.white)),
                        onPressed: () {
                          // TODO: Implement logic to share a safe route
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A2342),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Text('$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: content),
        ],
      ),
    );
  }
}
