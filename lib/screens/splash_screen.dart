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
    // نعطي الشاشة ثانيتين للعرض ثم نبدأ بطلب الأذونات
    Future.delayed(const Duration(seconds: 2), () {
      _requestPermissionsAndNavigate();
    });
  }

  // هذه الدالة تطلب كل الأذونات المطلوبة مباشرة من النظام
  Future<void> _requestPermissionsAndNavigate() async {
    // قائمة الأذونات التي يحتاجها تطبيقك
    final List<Permission> permissionsToRequest = [
      Permission.location,
      Permission.notification, // إذن الإشعارات
      Permission.camera,
      Permission.microphone,
    ];

    // طلب كل إذن في القائمة واحدًا تلو الآخر
    await permissionsToRequest.request();

    // التأكد من أن الواجهة ما زالت موجودة قبل الانتقال
    if (mounted) {
      // بعد الانتهاء من جميع الأذونات، انتقل إلى شاشة تسجيل الدخول
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
            const SizedBox(height: 20),
            // يمكن إضافة مؤشر تحميل هنا ليعلم المستخدم أن شيئًا ما يحدث
            const CircularProgressIndicator(
              color: Color(0xFF0A2342),
            ),
          ],
        ),
      ),
    );
  }
}
