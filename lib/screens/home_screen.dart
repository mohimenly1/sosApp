import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import '../widgets/home_grid_button.dart';
import '../widgets/alert_card_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Function to launch the blog URL
  Future<void> _launchBlogURL() async {
    final Uri url = Uri.parse('https://almarsad.co/');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A2342),
        elevation: 0,
        leading: const SizedBox.shrink(),
        centerTitle: false,
        title: Text("dashboard".tr()),
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
              // MODIFIED: This now shows the static blog card
              _buildBlogCard(),
              const SizedBox(height: 20),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('alerts')
                    .orderBy('timestamp', descending: true)
                    .limit(1)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildInfoCard("no_current_alerts".tr());
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("see_more_alerts".tr(),
                        style: const TextStyle(
                            color: Color(0xFF555555),
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios,
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
                    label: "ai_assistant".tr(),
                    onTap: () => Navigator.pushNamed(context, '/chat'),
                  ),
                  HomeGridButton(
                    icon: Icons.night_shelter_outlined,
                    label: "shelter".tr(),
                    onTap: () => Navigator.pushNamed(context, '/shelters_map'),
                  ),
                  HomeGridButton(
                    icon: Icons.cloud_outlined,
                    label: "weather".tr(),
                    onTap: () {
                      Navigator.pushNamed(context, '/weather');
                    },
                  ),
                  HomeGridButton(
                    icon: Icons.map_outlined,
                    label: "map".tr(),
                    onTap: () {
                      Navigator.pushNamed(context, '/user_map');
                    },
                  ),
                  HomeGridButton(
                    icon: Icons.report_gmailerrorred,
                    label: "send_report".tr(),
                    onTap: () {
                      Navigator.pushNamed(context, '/send_report');
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

  // NEW: A dedicated widget for the blog link card
  Widget _buildBlogCard() {
    return InkWell(
      onTap: _launchBlogURL,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.article_outlined, color: Colors.blue.shade700, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "official_blog".tr(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "visit_blog_prompt".tr(),
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for placeholder cards
  Widget _buildInfoCard(String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
          child: Text(title, style: const TextStyle(color: Colors.grey))),
    );
  }
}
