import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  Future<Map<String, dynamic>?> _getUserData() async {
    if (_userId == null) return null;
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(_userId).get();
    return userDoc.data();
  }

  String _translateUserType(String? userType) {
    switch (userType) {
      case 'individual':
        return "individual".tr();
      case 'rescue_team':
        return "rescue_team".tr();
      case 'government_entity':
        return "government_entity".tr();
      default:
        return "individual".tr();
    }
  }

  Future<void> _makePhoneCall(String number) async {
    final Uri url = Uri.parse('tel:$number');
    if (!await launchUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not make a call to $number')),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_account'.tr()),
        content: Text('are_you_sure_delete_account'.tr()),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('cancel'.tr())),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child:
                Text('delete'.tr(), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && _userId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .delete();
        await FirebaseAuth.instance.currentUser?.delete();

        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error: ${e.message}. Please sign in again to delete your account.')),
        );
      }
    }
  }

  void _showEmergencyNumbers() {
    final List<Map<String, String>> numbers = [
      {'key': 'field_medicine_ops_room', 'number': '0916288000'},
      {'key': 'central_ops_room', 'number': '0921910191'},
      {'key': 'ambulance_emergency_service', 'number': '0931911191'},
      {'key': 'national_safety_authority', 'number': '190'},
      {'key': 'general_electricity_company', 'number': '1418'},
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('emergency_numbers_title'.tr(),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: numbers.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final item = numbers[index];
                return ListTile(
                  title: Text(item['key']!.tr()),
                  subtitle: Text(item['number']!),
                  trailing: const Icon(Icons.call, color: Colors.green),
                  onTap: () => _makePhoneCall(item['number']!),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("profile_title".tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(
                child: Text('Failed to load profile: ${snapshot.error}'));
          }

          final data = snapshot.data!;

          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 8)
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
                      Text(data['name'] ?? 'N/A',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(_translateUserType(data['userType']),
                          style: const TextStyle(
                              fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildActionButton(
                  text: 'medical_file'.tr(),
                  onPressed: () =>
                      Navigator.pushNamed(context, '/medical_file'),
                  color: const Color(0xFF0A2342),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => _makePhoneCall('1412'),
                  child: Text(
                    'emergency_medical_support_center'.tr(),
                    style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline),
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  text: 'emergency_numbers_title'.tr(),
                  onPressed: _showEmergencyNumbers,
                  color: Colors.orange.shade700,
                ),
                const Spacer(),
                _buildActionButton(
                  text: 'edit_profile'.tr(),
                  onPressed: () =>
                      Navigator.pushNamed(context, '/edit_profile'),
                  color: Colors.green.shade700,
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  text: 'delete_account'.tr(),
                  onPressed: _deleteAccount,
                  color: Colors.red.shade700,
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton(
      {required String text,
      required VoidCallback onPressed,
      required Color color}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
      ),
    );
  }
}
