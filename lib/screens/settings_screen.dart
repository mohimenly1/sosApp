import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // State for the language dropdown
  String _selectedLanguage = 'English';
  final List<String> _languages = ['English', 'العربية'];

  // Function to handle the sign-out process
  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // After signing out, navigate to the login screen and remove all previous routes
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    } catch (e) {
      // Show an error message if sign-out fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0A2342);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("settings".tr()),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Rebuilding the options to match the new design
            _buildSettingsOption(
              icon: Icons.person_outline,
              title: "profile".tr(),
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
            const SizedBox(height: 16),
            _buildSettingsOption(
              icon: Icons.medical_services_outlined,
              title: "medical_file".tr(),
              onTap: () {
                Navigator.pushNamed(context, '/medical_file');
              },
            ),
            const SizedBox(height: 16),
            // MODIFIED: This now uses a DropdownButton
            _buildSettingsOption(
              icon: Icons.language_outlined,
              title: "language".tr(),
              trailing: DropdownButton<Locale>(
                value: context.locale,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                items: const [
                  DropdownMenuItem(value: Locale('en'), child: Text('English')),
                  DropdownMenuItem(value: Locale('ar'), child: Text('العربية')),
                ],
                onChanged: (newValue) {
                  if (newValue != null) {
                    // This command changes the language of the entire app
                    context.setLocale(newValue);
                  }
                },
              ),
              onTap: () {},
            ),
            // const SizedBox(height: 16),
            // _buildSettingsOption(
            //   icon: Icons.privacy_tip_outlined,
            //   title: "privacy_policy".tr(),
            //   onTap: () {/* TODO: Navigate to Privacy Policy */},
            // ),
            const SizedBox(height: 16),
            _buildSettingsOption(
              icon: Icons.logout,
              title: "sign_out".tr(),
              isDestructive: true, // To make the text red
              onTap: () => _signOut(context),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to create the classic button style from the image
  Widget _buildSettingsOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isDestructive ? Colors.red : const Color(0xFF0A2342)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: isDestructive ? Colors.red : Colors.black87,
                ),
              ),
            ),
            trailing ??
                const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
