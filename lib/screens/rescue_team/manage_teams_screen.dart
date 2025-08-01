import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_helper.dart'; // Import the database helper
import 'team_details_screen.dart';

class ManageTeamsScreen extends StatefulWidget {
  const ManageTeamsScreen({super.key});

  @override
  State<ManageTeamsScreen> createState() => _ManageTeamsScreenState();
}

class _ManageTeamsScreenState extends State<ManageTeamsScreen> {
  List<Map<String, dynamic>> _teams = [];
  bool _isLoading = true;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _initAndSyncData();
  }

  Future<void> _initAndSyncData() async {
    await _loadLocalTeams();
    _syncFirestoreTeams();
  }

  Future<void> _loadLocalTeams() async {
    if (_currentUserId == null) return;
    final localTeams = await _dbHelper.getMyRescueTeams(_currentUserId!);
    if (mounted) {
      setState(() {
        _teams = localTeams;
        _isLoading = false;
      });
    }
  }

  Future<void> _syncFirestoreTeams() async {
    if (_currentUserId == null) return;
    try {
      final teamsSnapshot = await FirebaseFirestore.instance
          .collection('rescue_teams')
          .where('creatorId', isEqualTo: _currentUserId)
          .get();

      await _dbHelper.clearRescueTeams();
      await _dbHelper.clearEvacuationRoutes();

      for (var teamDoc in teamsSnapshot.docs) {
        final teamData = teamDoc.data();

        final teamForDb = {
          'id': teamDoc.id,
          'name': teamData['name'],
          'membersCount': teamData['membersCount'],
          'assignedRouteId': teamData['assignedRouteId'],
          'creatorId': teamData['creatorId'],
        };
        await _dbHelper.insertRescueTeam(teamForDb);

        final routeId = teamData['assignedRouteId'];
        final routeDoc = await FirebaseFirestore.instance
            .collection('evacuation_routes')
            .doc(routeId)
            .get();
        if (routeDoc.exists) {
          final routeData = routeDoc.data()!;
          final startPoint = routeData['startPoint'] as GeoPoint;
          final endPoint = routeData['endPoint'] as GeoPoint;
          final routeForDb = {
            'id': routeDoc.id,
            'startPoint_lat': startPoint.latitude,
            'startPoint_lon': startPoint.longitude,
            'endPoint_lat': endPoint.latitude,
            'endPoint_lon': endPoint.longitude,
            'safetyLevel': routeData['safetyLevel'],
            'isOfflineAvailable': routeData['isOfflineAvailable'] ? 1 : 0,
          };
          await _dbHelper.insertEvacuationRoute(routeForDb);
        }
      }

      await _loadLocalTeams();
    } catch (e) {
      print("Failed to sync teams from Firestore: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Rescue Teams'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _teams.isEmpty
              ? const Center(
                  child: Text(
                    'No teams found.\nPress the "+" button to add a new team.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _syncFirestoreTeams,
                  child: ListView.builder(
                    itemCount: _teams.length,
                    itemBuilder: (context, index) {
                      final team = _teams[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading:
                              const Icon(Icons.group, color: Color(0xFF0A2342)),
                          title: Text(team['name'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${team['membersCount']} members'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    TeamDetailsScreen(teamId: team['id']),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
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
