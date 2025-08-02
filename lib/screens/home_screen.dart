import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/home_grid_button.dart';
import '../widgets/alert_card_widget.dart'; // Import the new widget

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A2342),
        elevation: 0,
        leading: const SizedBox.shrink(),
        centerTitle: false,
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white, size: 28),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildInfoCard("Today's News"),
              const SizedBox(height: 20),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('alerts')
                    .orderBy('timestamp', descending: true)
                    .limit(1)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildInfoCard("No Current Alerts");
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final latestAlert =
                      snapshot.data!.docs.first.data() as Map<String, dynamic>;

                  return AlertCardWidget(
                    title: latestAlert['title'] ?? 'No Title',
                    description: latestAlert['description'] ?? 'No Description',
                    disasterType: latestAlert['disasterType'] ?? 'Other',
                  );
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/all_alerts');
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('See More',
                        style: TextStyle(
                            color: Color(0xFF555555),
                            fontWeight: FontWeight.bold)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios,
                        size: 14, color: Color(0xFF555555)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  HomeGridButton(
                    icon: Icons.smart_toy_outlined,
                    label: 'chatbot',
                    onTap: () => Navigator.pushNamed(context, '/chat'),
                  ),
                  HomeGridButton(
                    icon: Icons.night_shelter_outlined,
                    label: 'Shelter',
                    onTap: () => Navigator.pushNamed(context, '/safe_route'),
                  ),
                  HomeGridButton(
                    icon: Icons.cloud_outlined,
                    label: 'Weather',
                    onTap: () {},
                  ),
                  HomeGridButton(
                    icon: Icons.map_outlined,
                    label: 'Map',
                    onTap: () {
                      Navigator.pushNamed(context, '/user_map');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A2342),
            ),
          ),
          const SizedBox(height: 12),
          Container(
              height: 20,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8))),
          const SizedBox(height: 10),
          Container(
              height: 20,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8))),
        ],
      ),
    );
  }
}
