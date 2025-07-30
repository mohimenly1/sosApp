import 'package:flutter/material.dart';
import '../widgets/home_grid_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // This is the main screen layout
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A2342),
        elevation: 0,
        // We can remove the back button from the main home screen
        leading: const SizedBox.shrink(),
        centerTitle: false,
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white, size: 28),
            onPressed: () {
              // UPDATED: Navigate to the new settings screen
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
              _buildInfoCard("Current alert"),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {},
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'See More',
                      style: TextStyle(
                        color: Color(0xFF555555),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Color(0xFF555555),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Grid for the main action buttons
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2, // Adjust aspect ratio as needed
                children: [
                  HomeGridButton(
                    icon: Icons.smart_toy_outlined,
                    label: 'chatbot',
                    onTap: () {
                      Navigator.pushNamed(context, '/chat');
                    },
                  ),
                  HomeGridButton(
                    icon: Icons.night_shelter_outlined, // Corrected icon
                    label: 'Shelter',
                    onTap: () {},
                  ),
                  HomeGridButton(
                    icon: Icons.cloud_outlined,
                    label: 'Weather',
                    onTap: () {},
                  ),
                  HomeGridButton(
                    icon: Icons.map_outlined,
                    label: 'Map',
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to build the info cards for news and alerts
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
          // Placeholder for content
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}
