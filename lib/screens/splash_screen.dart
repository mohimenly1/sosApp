import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../auth/auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Wait for 3 seconds before requesting permissions and navigating
    Future.delayed(const Duration(seconds: 3), () {
      _requestPermissionsAndNavigate();
    });
  }

  Future<void> _requestPermissionsAndNavigate() async {
    // UPDATED: A comprehensive list of all permissions needed for the app.
    // This ensures all features like maps, camera, and notifications work correctly.
    await [
      Permission.location, // For all map and location features.
      Permission.notification, // To receive emergency alerts.
      Permission.camera, // To take photos for reports.
      Permission.microphone, // For voice notes in reports.
      Permission.storage, // For accessing files on older Android versions.
      Permission
          .photos, // For accessing the photo gallery on newer Android/iOS.
    ].request();

    if (mounted) {
      // Navigate to the AuthGate which will direct the user to the correct screen.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthGate()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'lib/assets/logo.jpeg', // Make sure you have this asset
              width: 180,
              height: 180,
            ),
            const SizedBox(height: 32),
            const Text(
              'ResQTrack',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A2342),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              color: Color(0xFF0A2342),
            ),
          ],
        ),
      ),
    );
  }
}
