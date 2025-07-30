import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'team_details_screen.dart'; // Import the new details screen

class ManageTeamsScreen extends StatelessWidget {
  const ManageTeamsScreen({super.key});

  // Function to handle team and route deletion
  Future<void> _deleteTeam(
      BuildContext context, String teamId, String routeId) async {
    try {
      // Using a batch write to delete both documents atomically
      final batch = FirebaseFirestore.instance.batch();

      final teamRef =
          FirebaseFirestore.instance.collection('rescue_teams').doc(teamId);
      final routeRef = FirebaseFirestore.instance
          .collection('evacuation_routes')
          .doc(routeId);

      batch.delete(teamRef);
      batch.delete(routeRef);

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Team deleted successfully'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete team: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Rescue Teams'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rescue_teams')
            .where('creatorId', isEqualTo: currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No teams found.\nPress the "+" button to add a new team.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final teams = snapshot.data!.docs;

          return ListView.builder(
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];
              final teamData = team.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.group, color: Color(0xFF0A2342)),
                  title: Text(teamData['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${teamData['membersCount']} members'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        // Show a confirmation dialog before deleting
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Confirm Deletion'),
                            content: const Text(
                                'Are you sure you want to delete this team and its route? This action cannot be undone.'),
                            actions: [
                              TextButton(
                                  child: const Text('Cancel'),
                                  onPressed: () => Navigator.of(ctx).pop()),
                              TextButton(
                                child: const Text('Delete',
                                    style: TextStyle(color: Colors.red)),
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  _deleteTeam(context, team.id,
                                      teamData['assignedRouteId']);
                                },
                              ),
                            ],
                          ),
                        );
                      } else if (value == 'edit') {
                        // TODO: Navigate to an edit screen
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child:
                            Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                  onTap: () {
                    // Navigate to team details screen, passing the team ID
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TeamDetailsScreen(teamId: team.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add_team');
        },
        backgroundColor: const Color(0xFF0A2342),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
