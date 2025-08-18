import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'safe_route_details_screen.dart'; // We will create this next
import 'package:easy_localization/easy_localization.dart';

class SafeRoutesScreen extends StatelessWidget {
  const SafeRoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Your Safe Routes')),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user_safe_route_access')
            .where('userId', isEqualTo: currentUser?.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                tr('No safe routes have been shared with you yet.'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final accessDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: accessDocs.length,
            itemBuilder: (context, index) {
              final accessData =
                  accessDocs[index].data() as Map<String, dynamic>;
              return RouteInfoCard(
                routeId: accessData['routeId'],
                accessData: accessData,
              );
            },
          );
        },
      ),
    );
  }
}

class RouteInfoCard extends StatelessWidget {
  final String routeId;
  final Map<String, dynamic> accessData;

  const RouteInfoCard(
      {super.key, required this.routeId, required this.accessData});

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat.yMMMd()
        .add_jm()
        .format((accessData['timestamp'] as Timestamp).toDate());

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('evacuation_routes')
          .doc(routeId)
          .get(),
      builder: (context, routeSnapshot) {
        if (!routeSnapshot.hasData) {
          return Card(child: ListTile(title: Text(tr('Loading route...'))));
        }
        if (!routeSnapshot.data!.exists) {
          return Card(
              child: ListTile(title: Text(tr('Route data is missing.'))));
        }

        // final routeData = routeSnapshot.data!.data() as Map<String, dynamic>; // لم يتم استخدامه

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.shield_outlined,
                color: Colors.green, size: 40),
            title: Text(tr('Safe Route Assigned'),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(tr('Shared on: $formattedDate')),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SafeRouteDetailsScreen(routeId: routeId),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
