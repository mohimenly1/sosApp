import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Import FCM
import 'package:resq_track4/screens/all_alerts_screen.dart';
import 'package:resq_track4/screens/all_news_screen.dart';
import 'package:resq_track4/screens/chat/user_chat_list_screen.dart';
import 'package:resq_track4/screens/edit_profile_screen.dart';
import 'package:resq_track4/screens/forgot_password_screen.dart';
import 'package:resq_track4/screens/profile_screen.dart';
import 'package:resq_track4/screens/rescue_home_screen.dart';
import 'package:resq_track4/screens/rescue_team/active_reports_screen.dart';
import 'package:resq_track4/screens/rescue_team/add_shelter_screen.dart';
import 'package:resq_track4/screens/rescue_team/chat_list_screen.dart';
import 'package:resq_track4/screens/safe_routes_screen.dart';
import 'package:resq_track4/screens/send_report_screen.dart';
import 'package:resq_track4/screens/shelters_map_screen.dart';
import 'package:resq_track4/screens/user_map_screen.dart';
import 'package:resq_track4/screens/weather_screen.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/sos_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/medical_file_screen.dart';

import 'screens/rescue_team/manage_teams_screen.dart';
import 'screens/rescue_team/add_team_screen.dart';
import 'screens/rescue_team/send_alert_screen.dart';
import 'widgets/main_scaffold.dart';
import 'auth/auth_gate.dart'; // Import the AuthGate
import 'package:easy_localization/easy_localization.dart'; // 1. Import easy_localization

class GovHomeScreen extends StatelessWidget {
  const GovHomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      body: Scaffold(
        appBar: AppBar(title: Text('Government Dashboard')),
        body: const Center(child: Text('Welcome, Government Entity!')),
      ),
    );
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await NotificationService().initNotifications();

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  await EasyLocalization.ensureInitialized();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations', // The path to your translation files
      fallbackLocale: const Locale('en'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      title: 'ResQTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0A2342)),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFF0A2342),
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const MainScaffold(body: HomeScreen()),
        '/chat': (context) => const ChatScreen(),
        '/rescue_home': (context) => const RescueHomeScreen(),
        '/gov_home': (context) => const GovHomeScreen(),
        '/sos': (context) => const SosScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/medical_file': (context) => const MedicalFileScreen(),
        '/manage_teams': (context) => const ManageTeamsScreen(),
        '/add_team': (context) => const AddTeamScreen(),
        '/send_alert': (context) => const SendAlertScreen(),
        '/all_alerts': (context) => const AllAlertsScreen(),
        '/active_reports': (context) => const ActiveReportsScreen(),
        '/safe_route': (context) => const SafeRoutesScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/user_map': (context) => const UserMapScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/chat_list': (context) => const ChatListScreen(),
        '/user_chat_list': (context) => const UserChatListScreen(),
        '/send_report': (context) => const SendReportScreen(),
        '/edit_profile': (context) => const EditProfileScreen(),
        '/weather': (context) => const WeatherScreen(),
        '/all_news': (context) => const AllNewsScreen(),
        '/add_shelter': (context) => const AddShelterScreen(),
        '/shelters_map': (context) => const SheltersMapScreen(),
      },
    );
  }
}
