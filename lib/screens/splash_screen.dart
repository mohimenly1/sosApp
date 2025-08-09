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
    Future.delayed(const Duration(seconds: 4), () {
      // Increased duration slightly
      _requestPermissionsAndNavigate();
    });
  }

  Future<void> _requestPermissionsAndNavigate() async {
    // A comprehensive list of all permissions needed for the app.
    await [
      Permission.location,
      Permission.notification,
      Permission.camera,
      Permission.microphone,
      Permission.storage,
      Permission.photos,
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'lib/assets/logo.jpeg', // Make sure you have this asset
                width: 180,
                height: 180,
              ),
              const SizedBox(height: 32),
              // NEW: Added the welcome text
              const Text(
                'مرحبًا بك في ResQTrack',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A2342),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // NEW: Added the descriptive text
              Text(
                'نحن هنا لنساعدك في حالات الطوارئ وتتبع فرق الإنقاذ بدقة وسرعة.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                color: Color(0xFF0A2342),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
