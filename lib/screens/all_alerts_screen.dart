import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/database_helper.dart'; // 1. Import our database helper

class AllAlertsScreen extends StatefulWidget {
  const AllAlertsScreen({super.key});

  @override
  State<AllAlertsScreen> createState() => _AllAlertsScreenState();
}

class _AllAlertsScreenState extends State<AllAlertsScreen> {
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _initAndSyncData();
  }

  Future<void> _initAndSyncData() async {
    // 2. Load local data first for instant UI
    await _loadLocalAlerts();
    // 3. Then, fetch fresh data from Firestore to update local DB and UI
    _syncFirestoreAlerts();
  }

  Future<void> _loadLocalAlerts() async {
    final localAlerts = await _dbHelper.getAllAlerts();
    if (mounted) {
      setState(() {
        _alerts = localAlerts;
        _isLoading = false;
      });
    }
  }

  Future<void> _syncFirestoreAlerts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('alerts')
          .orderBy('timestamp', descending: true)
          .get();

      // Clear old local data before inserting new data
      await _dbHelper.clearAlerts();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final location = data['location'] as GeoPoint;
        final timestamp = (data['timestamp'] as Timestamp).toDate();

        // Prepare data in a format that matches our SQLite table
        final alertForDb = {
          'id': doc.id,
          'title': data['title'],
          'description': data['description'],
          'disasterType': data['disasterType'],
          'location_lat': location.latitude,
          'location_lon': location.longitude,
          'timestamp': timestamp.toIso8601String(), // Store date as a string
        };
        await _dbHelper.insertAlert(alertForDb);
      }

      // After syncing, reload the data from the local DB to refresh the UI
      await _loadLocalAlerts();
    } catch (e) {
      print("Failed to sync from Firestore: $e");
      // If syncing fails, the user will still see the old local data
    }
  }

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alerts.isEmpty
              ? const Center(
                  child: Text('No alerts have been issued yet.',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                )
              : RefreshIndicator(
                  onRefresh:
                      _syncFirestoreAlerts, // Allow user to pull-to-refresh
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _alerts.length,
                    itemBuilder: (context, index) {
                      final alert = _alerts[index];
                      // Parse the timestamp string back to a DateTime object
                      final timestamp = DateTime.parse(alert['timestamp']);
                      final formattedDate =
                          DateFormat.yMMMd().add_jm().format(timestamp);

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.red.shade100,
                            child: Icon(
                              _getDisasterIcon(
                                  alert['disasterType'] ?? 'other'),
                              color: Colors.red.shade700,
                            ),
                          ),
                          title: Text(alert['title'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${alert['description']}\nIssued: $formattedDate',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
