import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MainScaffold extends StatefulWidget {
  final Widget body;
  const MainScaffold({super.key, required this.body});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 2;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (mounted) {
          setState(() {
            _userRole = doc.data()?['userType'];
          });
        }
      } catch (e) {
        // Handle potential errors, e.g., user document not found
        print("Could not fetch user role: $e");
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // TODO: Add navigation logic here based on index
  }

  void _onFabTapped() {
    // Differentiated action based on user role
    if (_userRole == 'rescue_team') {
      Navigator.pushNamed(context, '/send_alert');
    } else {
      Navigator.pushNamed(context, '/sos');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.body,
      floatingActionButton: FloatingActionButton(
        onPressed: _onFabTapped,
        backgroundColor: Colors.white,
        elevation: 4.0,
        shape: const CircleBorder(),
        child: Text(
          // Change FAB text based on role
          _userRole == 'rescue_team' ? 'ALERT' : 'SOS',
          style: TextStyle(
            color: Colors.red.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF0A2342),
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _buildNavItem(icon: Icons.map_outlined, index: 0, label: 'Map'),
              _buildNavItem(
                  icon: Icons.list_alt_outlined, index: 1, label: 'Reports'),
              const SizedBox(width: 40), // The space for the notch
              _buildNavItem(
                  icon: Icons.notifications_outlined,
                  index: 3,
                  label: 'Alerts'),
              _buildNavItem(
                  icon: Icons.chat_bubble_outline, index: 4, label: 'Chat'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      {required IconData icon, required int index, required String label}) {
    return IconButton(
      icon: Icon(
        icon,
        color: _selectedIndex == index
            ? Colors.white
            : Colors.white.withOpacity(0.6),
        size: 28,
      ),
      onPressed: () => _onItemTapped(index),
      tooltip: label,
    );
  }
}
