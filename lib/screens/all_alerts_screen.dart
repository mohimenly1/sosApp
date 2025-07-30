import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting

class AllAlertsScreen extends StatelessWidget {
  const AllAlertsScreen({super.key});

  // Helper function to get an icon based on the disaster type
  IconData _getDisasterIcon(String disasterType) {
    switch (disasterType.toLowerCase()) {
      case 'fire':
        return Icons.local_fire_department;
      case 'flood':
        return Icons.water_drop;
      case 'earthquake':
        return Icons.vibration;
      case 'hurricane':
        return Icons.cyclone;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Emergency Alerts'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('alerts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No alerts have been issued yet.',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
            );
          }

          final alerts = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index].data() as Map<String, dynamic>;
              final timestamp = (alert['timestamp'] as Timestamp).toDate();
              final formattedDate =
                  DateFormat.yMMMd().add_jm().format(timestamp);

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.shade100,
                    child: Icon(
                      _getDisasterIcon(alert['disasterType'] ?? 'other'),
                      color: Colors.red.shade700,
                    ),
                  ),
                  title: Text(alert['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${alert['description']}\nIssued: $formattedDate',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
