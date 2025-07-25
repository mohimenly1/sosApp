import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _currentPermissionIndex = 0;
  final List<_PermissionRequest> _permissionRequests = [
    const _PermissionRequest(
        Permission.location, 'Allow access to your location?'),
    const _PermissionRequest(
        Permission.sms, 'Allow access to send and read SMS?'),
    const _PermissionRequest(Permission.camera, 'Allow access to your camera?'),
    const _PermissionRequest(
        Permission.microphone, 'Allow access to your microphone?'),
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      _showNextPermissionDialog();
    });
  }

  void _showNextPermissionDialog() async {
    if (_currentPermissionIndex >= _permissionRequests.length) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    final req = _permissionRequests[_currentPermissionIndex];
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Permission Required',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF0A2342))),
        content: Text(req.message, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () async {
              await req.permission.request();
              Navigator.of(context).pop();
              setState(() {
                _currentPermissionIndex++;
              });
              _showNextPermissionDialog();
            },
            child: const Text('Allow',
                style: TextStyle(
                    color: Color(0xFF0A2342), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
              'lib/assets/Untitled.gif',
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
          ],
        ),
      ),
    );
  }
}

class _PermissionRequest {
  final Permission permission;
  final String message;
  const _PermissionRequest(this.permission, this.message);
}
