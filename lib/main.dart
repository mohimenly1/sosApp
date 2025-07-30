import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:resq_track4/screens/medical_file_screen.dart';
import 'package:resq_track4/screens/rescue_team/add_team_screen.dart';
import 'package:resq_track4/screens/rescue_team/manage_teams_screen.dart';
import 'package:resq_track4/screens/settings_screen.dart';
import 'package:resq_track4/screens/sos_screen.dart';
import 'firebase_options.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/rescue_home_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'widgets/main_scaffold.dart'; // Import the new scaffold

// Placeholder screens for the other roles

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF0A2342),
              width: 2.0,
            ),
          ),
        ),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        // UPDATED: Wrap HomeScreen with the new MainScaffold
        '/home': (context) => const MainScaffold(body: HomeScreen()),
        '/chat': (context) => const ChatScreen(),
        '/rescue_home': (context) => const RescueHomeScreen(),
        '/gov_home': (context) => const GovHomeScreen(),
        '/sos': (context) => const SosScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/medical_file': (context) => const MedicalFileScreen(),
        '/manage_teams': (context) => const ManageTeamsScreen(),
        '/add_team': (context) => const AddTeamScreen(),
      },
    );
  }
}
