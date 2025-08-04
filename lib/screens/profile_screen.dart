import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  // A single function to fetch both user and medical data
  Future<Map<String, dynamic>> _getCombinedUserData() async {
    if (_userId == null) throw Exception("User not logged in");

    // Fetch user data
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(_userId).get();
    if (!userDoc.exists) throw Exception("User data not found");

    final userData = userDoc.data()!;
    Map<String, dynamic> combinedData = Map.from(userData);

    // Fetch medical data if the link exists
    final medicalFileId = userData['medicalFileId'];
    if (medicalFileId != null) {
      final medicalDoc = await FirebaseFirestore.instance
          .collection('medical_files')
          .doc(medicalFileId)
          .get();
      if (medicalDoc.exists) {
        combinedData.addAll(medicalDoc.data()!);
      }
    }
    return combinedData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              // TODO: Navigate to an "Edit Profile" screen
            },
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getCombinedUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
                child: Text('Failed to load profile: ${snapshot.error}'));
          }

          final data = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Profile Header Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 8,
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey,
                        child:
                            Icon(Icons.person, size: 40, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        data['name'] ?? 'N/A',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (data['userType'] as String?)
                                ?.replaceAll('_', ' ')
                                .toUpperCase() ??
                            'INDIVIDUAL',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Details Section
                _buildDetailRow(
                    "Date of Birth:", "May 15, 1994"), // Placeholder
                _buildDetailRow(
                    "Medical Condition:", data['chronicDiseases'] ?? 'None'),
                _buildDetailRow("Allergies:", data['allergies'] ?? 'None'),
                _buildDetailRow("Blood Type:", data['bloodType'] ?? 'N/A'),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper widget to create the classic detail row
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A2342),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
