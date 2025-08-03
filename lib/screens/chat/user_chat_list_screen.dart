import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'p2p_chat_screen.dart';

class UserChatListScreen extends StatefulWidget {
  const UserChatListScreen({super.key});

  @override
  State<UserChatListScreen> createState() => _UserChatListScreenState();
}

class _UserChatListScreenState extends State<UserChatListScreen> {
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  // Fetches the rescue teams that have shared a safe route with the current user
  Future<List<DocumentSnapshot>> _getAccessibleRescueTeams() async {
    if (_currentUserId == null) return [];

    // 1. Find all routes shared with the user
    final accessSnapshot = await FirebaseFirestore.instance
        .collection('user_safe_route_access')
        .where('userId', isEqualTo: _currentUserId)
        .get();

    if (accessSnapshot.docs.isEmpty) return [];

    final grantedByRescueUserIds = accessSnapshot.docs
        .map((doc) => doc.data()['accessGrantedBy'] as String)
        .toSet() // Use a Set to avoid duplicates
        .toList();

    if (grantedByRescueUserIds.isEmpty) return [];

    // 2. Find all rescue team users from the IDs collected
    final rescueTeamsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('uid', whereIn: grantedByRescueUserIds)
        .get();

    return rescueTeamsSnapshot.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Rescue Teams')),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _getAccessibleRescueTeams(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No rescue teams have shared a route with you yet.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final rescueTeams = snapshot.data!;

          return ListView.builder(
            itemCount: rescueTeams.length,
            itemBuilder: (context, index) {
              final teamUser =
                  rescueTeams[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF0A2442),
                    child: Icon(Icons.security_outlined, color: Colors.white),
                  ),
                  title: Text(teamUser['name'] ?? 'Rescue Team'),
                  subtitle: const Text('Tap to start a conversation'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => P2PChatScreen(
                          recipientId: teamUser['uid'],
                          recipientName: teamUser['name'] ?? 'Rescue Team',
                        ),
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
