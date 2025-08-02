import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

      Navigator.of(context)
          .pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0A2342);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          _buildSettingsSectionTitle("Account"),
          _buildSettingsCard([
            _buildSettingsTile(
              icon: Icons.person_outline,
              title: "Profile",
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
            _buildSettingsTile(
              icon: Icons.medical_services_outlined,
              title: "Medical File",
              onTap: () {
                Navigator.pushNamed(context, '/medical_file');
              },
            ),
          ]),
          const SizedBox(height: 20),
          _buildSettingsSectionTitle("Preferences"),
          _buildSettingsCard([
            SwitchListTile(
              title: const Text("العربية",
                  style: TextStyle(fontWeight: FontWeight.w500)),
              value: false,
              onChanged: (bool value) {},
              secondary:
                  const Icon(Icons.language_outlined, color: primaryColor),
              activeColor: primaryColor,
            ),
            _buildSettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: "Privacy Policy",
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 20),
          _buildSettingsCard([
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                "Sign Out",
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
              ),
              onTap: () => _signOut(context),
            ),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSettingsSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsTile(
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0A2342)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}
