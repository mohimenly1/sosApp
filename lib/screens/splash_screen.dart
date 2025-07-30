import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 2), () {
      _requestPermissionsAndNavigate();
    });
  }

  Future<void> _requestPermissionsAndNavigate() async {
    final List<Permission> permissionsToRequest = [
      Permission.location,
      Permission.notification,
      Permission.camera,
      Permission.microphone,
    ];

    await permissionsToRequest.request();

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
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
              'lib/assets/logo.jpeg',
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
