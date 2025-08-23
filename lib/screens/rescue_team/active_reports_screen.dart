import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'report_details_screen.dart';
import 'package:easy_localization/easy_localization.dart';

class ActiveReportsScreen extends StatelessWidget {
  const ActiveReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('active_distress_signals'.tr()),
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
            return Center(
              child: Text(
                'no_active_distress_signals'.tr(),
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final reports = snapshot.data!.docs;

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];

              final dataObject = report.data();
              if (dataObject is! Map<String, dynamic>) {
                return Card(
                    child: ListTile(title: Text('invalid_report_format'.tr())));
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
                  title: UserInfoWidget(userId: data['userId'] ?? ''),
                  subtitle: Text(
                    '${data['content'] ?? 'no_description'.tr()}\n${'reported_at'.tr()} $formattedDate',
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

class UserInfoWidget extends StatelessWidget {
  final String userId;
  const UserInfoWidget({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) {
      return Text('unknown_user'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData && snapshot.data!.exists) {
            final userData = snapshot.data!.data() as Map<String, dynamic>;
            return Text(userData['name'] ?? 'unknown_user'.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold));
          } else {
            return Text('deleted_user'.tr(),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    fontStyle: FontStyle.italic));
          }
        }

        return Text('loading_user'.tr(),
            style: const TextStyle(fontStyle: FontStyle.italic));
      },
    );
  }
}
