import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart'; // To play audio from URL
import 'active_reports_screen.dart'; // For the UserInfoWidget

class ReportDetailsScreen extends StatefulWidget {
  final String reportId;
  const ReportDetailsScreen({super.key, required this.reportId});

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  void _showShareRouteDialog(String distressedUserId) {
    final rescueUserId = FirebaseAuth.instance.currentUser?.uid;
    if (rescueUserId == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: const Row(
            children: [
              Icon(Icons.route_outlined, color: Color(0xFF0A2342)),
              SizedBox(width: 8),
              Text('Select a Safe Route'),
            ],
          ),
          titleTextStyle: const TextStyle(
            color: Color(0xFF0A2342),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('rescue_teams')
                  .where('creatorId', isEqualTo: rescueUserId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text(
                      'You have not created any teams with routes yet.');
                }

                final teams = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: teams.length,
                  itemBuilder: (context, index) {
                    final team = teams[index].data() as Map<String, dynamic>;
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        leading:
                            const Icon(Icons.group, color: Color(0xFF0A2342)),
                        title: Text(team['name']),
                        trailing: const Icon(Icons.send, color: Colors.green),
                        onTap: () {
                          _shareRoute(
                            distressedUserId: distressedUserId,
                            routeId: team['assignedRouteId'],
                            rescueUserId: rescueUserId,
                          );
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareRoute({
    required String distressedUserId,
    required String routeId,
    required String rescueUserId,
  }) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      final accessDocRef =
          FirebaseFirestore.instance.collection('user_safe_route_access').doc();
      batch.set(accessDocRef, {
        'userId': distressedUserId,
        'routeId': routeId,
        'accessGrantedBy': rescueUserId,
        'timestamp': Timestamp.now(),
      });

      final reportDocRef =
          FirebaseFirestore.instance.collection('reports').doc(widget.reportId);
      batch.update(reportDocRef, {
        'status': 'responded',
        'assignedRouteId': routeId,
      });

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Safe route shared successfully!'),
            backgroundColor: Colors.green),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share route: $e')),
      );
    }
  }

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
          final status = reportData['status'] ?? 'pending';

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
                      // UPDATED: Content section now handles text, image, and audio
                      _buildContentSection(reportData),
                      _buildDetailRow(Icons.category, 'Disaster Type',
                          Text(reportData['disasterType'] ?? 'N/A')),
                      _buildDetailRow(Icons.timer, 'Time', Text(formattedDate)),
                      const SizedBox(height: 20),
                      if (status == 'responded' &&
                          reportData['assignedRouteId'] != null)
                        SharedRouteMap(routeId: reportData['assignedRouteId'])
                      else
                        ElevatedButton.icon(
                          icon: const Icon(Icons.route_outlined,
                              color: Colors.white),
                          label: const Text('Share Safe Route',
                              style: TextStyle(color: Colors.white)),
                          onPressed: () {
                            _showShareRouteDialog(reportData['userId']);
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

  // NEW: A dedicated widget to display different types of content
  Widget _buildContentSection(Map<String, dynamic> data) {
    final String description = data['content'] ?? '';
    final String? imageUrl = data['imageUrl'];
    final String? audioUrl = data['audioUrl'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow(
            Icons.description,
            'Description',
            Text(description.isNotEmpty
                ? description
                : 'No description provided.')),
        if (imageUrl != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const Center(child: CircularProgressIndicator()),
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.error, color: Colors.red),
              ),
            ),
          ),
        if (audioUrl != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: AudioPlayerWidget(url: audioUrl),
          ),
      ],
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

// NEW: A dedicated widget to play audio from a URL
class AudioPlayerWidget extends StatefulWidget {
  final String url;
  const AudioPlayerWidget({super.key, required this.url});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayer() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource(widget.url));
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.audiotrack, color: Color(0xFF0A2342)),
        title: const Text('Voice Report'),
        trailing: IconButton(
          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: _togglePlayer,
        ),
      ),
    );
  }
}

// ... (SharedRouteMap and UserInfoWidget remain the same)
class SharedRouteMap extends StatelessWidget {
  final String routeId;
  const SharedRouteMap({super.key, required this.routeId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('evacuation_routes')
          .doc(routeId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text('Assigned route not found.',
              style: TextStyle(color: Colors.red));
        }

        final routeData = snapshot.data!.data() as Map<String, dynamic>;
        final startPointGeo = routeData['startPoint'] as GeoPoint;
        final endPointGeo = routeData['endPoint'] as GeoPoint;
        final startPoint =
            LatLng(startPointGeo.latitude, startPointGeo.longitude);
        final endPoint = LatLng(endPointGeo.latitude, endPointGeo.longitude);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Assigned Safe Route',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: startPoint,
                  initialZoom: 13,
                ),
                children: [
                  TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                          points: [startPoint, endPoint],
                          strokeWidth: 5.0,
                          color: Colors.green),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: startPoint,
                        width: 80,
                        height: 80,
                        child: const Column(children: [
                          Icon(Icons.location_on, color: Colors.blue, size: 40),
                          Text('Start')
                        ]),
                      ),
                      Marker(
                        point: endPoint,
                        width: 80,
                        height: 80,
                        child: const Column(children: [
                          Icon(Icons.location_on,
                              color: Colors.green, size: 40),
                          Text('End')
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
