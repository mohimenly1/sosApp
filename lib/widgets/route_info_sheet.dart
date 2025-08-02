import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RouteInfoSheet extends StatelessWidget {
  final DocumentSnapshot routeDoc;
  const RouteInfoSheet({super.key, required this.routeDoc});

  // Helper function to find the team that created this route
  Future<DocumentSnapshot?> _getTeamForRoute() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('rescue_teams')
        .where('assignedRouteId', isEqualTo: routeDoc.id)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final routeData = routeDoc.data() as Map<String, dynamic>;
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Safe Route Details',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A2342))),
          const Divider(height: 24),
          _buildDetailRow(Icons.security, 'Safety Level',
              (routeData['safetyLevel'] ?? 'N/A').toString()),
          _buildDetailRow(Icons.wifi_off, 'Offline Available',
              (routeData['isOfflineAvailable'] ?? false) ? 'Yes' : 'No'),
          const SizedBox(height: 16),
          const Text('Managed By:',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          FutureBuilder<DocumentSnapshot?>(
            future: _getTeamForRoute(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ListTile(
                    leading: CircularProgressIndicator(),
                    title: Text('Loading team info...'));
              }
              if (!snapshot.hasData || snapshot.data == null) {
                return const ListTile(
                    leading: Icon(Icons.error),
                    title: Text('Team information not found.'));
              }
              final teamData = snapshot.data!.data() as Map<String, dynamic>;
              return Card(
                elevation: 0,
                color: Colors.blue.shade50,
                child: ListTile(
                  leading: const Icon(Icons.group, color: Color(0xFF0A2342)),
                  title: Text(teamData['name'] ?? 'Unnamed Team',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${teamData['membersCount'] ?? 0} members'),
                ),
              );
            },
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
