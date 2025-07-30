import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'report_details_screen.dart';

class ActiveReportsScreen extends StatelessWidget {
  const ActiveReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Distress Signals'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .where('status', isEqualTo: 'pending')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No active distress signals at the moment.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final reports = snapshot.data!.docs;

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              // Safety check to ensure data is in the expected format
              final dataObject = report.data();
              if (dataObject is! Map<String, dynamic>) {
                return const Card(
                    child: ListTile(title: Text('Invalid report format.')));
              }
              final data = dataObject;

              final timestamp =
                  (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
              final formattedDate =
                  DateFormat.yMMMd().add_jm().format(timestamp);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.sos, color: Colors.red, size: 40),
                  title: UserInfoWidget(
                      userId: data['userId'] ?? ''), // Pass userId safely
                  subtitle: Text(
                    '${data['content'] ?? 'No description.'}\nReported at: $formattedDate',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ReportDetailsScreen(reportId: report.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Helper widget with the fix for the null error
class UserInfoWidget extends StatelessWidget {
  final String userId;
  const UserInfoWidget({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) {
      return const Text('Unknown User',
          style: TextStyle(fontWeight: FontWeight.bold));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // THE FIX: Check if the document actually exists before trying to read its data
          if (snapshot.hasData && snapshot.data!.exists) {
            final userData = snapshot.data!.data() as Map<String, dynamic>;
            return Text(userData['name'] ?? 'Unknown User',
                style: const TextStyle(fontWeight: FontWeight.bold));
          } else {
            // This handles the case where the user who made the report was deleted
            return const Text('Deleted User',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    fontStyle: FontStyle.italic));
          }
        }
        // While data is loading
        return const Text('Loading user...',
            style: TextStyle(fontStyle: FontStyle.italic));
      },
    );
  }
}
