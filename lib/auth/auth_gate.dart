import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resq_track4/main.dart';
import 'package:resq_track4/screens/rescue_home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';

import '../widgets/main_scaffold.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // While checking the auth state, show a loading spinner
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        // If a user is logged in
        if (snapshot.hasData) {
          // Redirect to the correct dashboard based on their role
          return RoleBasedRedirect(userId: snapshot.data!.uid);
        }

        // If no user is logged in, show the login screen
        return const LoginScreen();
      },
    );
  }
}

// This helper widget fetches the user's role and navigates accordingly
class RoleBasedRedirect extends StatelessWidget {
  final String userId;
  const RoleBasedRedirect({super.key, required this.userId});

  Future<String?> _getUserRole() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (docSnapshot.exists) {
        return docSnapshot.data()?['userType'];
      }
    } catch (e) {
      print("Error fetching user role: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getUserRole(),
      builder: (context, snapshot) {
        // While fetching the role, show a loading spinner
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        // If role is fetched, navigate to the correct screen
        if (snapshot.hasData) {
          final userType = snapshot.data;
          switch (userType) {
            case 'individual':
              return const MainScaffold(body: HomeScreen());
            case 'rescue_team':
              return const RescueHomeScreen();
            case 'government_entity':
              return const GovHomeScreen();
            default:
              // Fallback for unknown roles
              return const MainScaffold(body: HomeScreen());
          }
        }

        // If there's an error or no role, default to the login screen
        return const LoginScreen();
      },
    );
  }
}
