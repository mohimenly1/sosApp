import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/home_grid_button.dart';
import '../widgets/alert_card_widget.dart';
import '../services/news_service.dart'; // 1. Import the news service

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NewsService _newsService = NewsService();
  late Future<List<NewsArticle>> _newsFuture;

  @override
  void initState() {
    super.initState();
    _newsFuture = _newsService.fetchNews();
  }

  Future<void> _launchURL(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
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
              // 2. Use a FutureBuilder to display the latest news
              FutureBuilder<List<NewsArticle>>(
                future: _newsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildInfoCard("Loading News...");
                  }
                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return _buildInfoCard("News Not Available");
                  }
                  final latestArticle = snapshot.data!.first;
                  return _buildNewsCard(context, latestArticle);
                },
              ),
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
                    Text('See More Alerts',
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
                    label: 'AI Assistant',
                    onTap: () => Navigator.pushNamed(context, '/chat'),
                  ),
                  HomeGridButton(
                    icon: Icons.night_shelter_outlined,
                    label: 'Shelter',
                    onTap: () => Navigator.pushNamed(context, '/shelters_map'),
                  ),
                  HomeGridButton(
                    icon: Icons.cloud_outlined,
                    label: 'Weather',
                    onTap: () {
                      Navigator.pushNamed(context, '/weather');
                    },
                  ),
                  HomeGridButton(
                    icon: Icons.map_outlined,
                    label: 'Map',
                    onTap: () {
                      Navigator.pushNamed(context, '/user_map');
                    },
                  ),
                  HomeGridButton(
                    icon: Icons.report_gmailerrorred,
                    label: 'Send Report',
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

  // 3. New widget to display the news article attractively
  Widget _buildNewsCard(BuildContext context, NewsArticle article) {
    return InkWell(
      onTap: () => _launchURL(article.url),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.urlToImage != null)
              Image.network(
                article.urlToImage!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                    height: 150,
                    child: Center(child: Text("Image not available"))),
              ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("TODAY'S NEWS",
                      style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(article.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/all_news'),
                      child: const Text("Read More..."),
                    ),
                  )
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
