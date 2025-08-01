import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../auth/auth_gate.dart'; // 1. Import the new AuthGate

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      _requestPermissionsAndNavigate();
    });
  }

  Future<void> _requestPermissionsAndNavigate() async {
    // Requesting permissions remains the same
    await [
      Permission.location,
      Permission.notification,
      Permission.camera,
      Permission.microphone,
    ].request();

    if (mounted) {
      // 2. Navigate to the AuthGate instead of the login screen
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
