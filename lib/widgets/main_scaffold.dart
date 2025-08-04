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
        print("Could not fetch user role: $e");
      }
    }
  }

  void _onItemTapped(int index) {
    // Prevent navigating to the same page
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0: // Map
        Navigator.pushNamed(context, '/user_map');
        break;
      case 1: // Reports (for rescue teams) or Alerts (for users)
        if (_userRole == 'rescue_team') {
          Navigator.pushNamed(context, '/active_reports');
        } else {
          Navigator.pushNamed(context, '/send_report');
        }
        break;
      case 3: // Alerts
        Navigator.pushNamed(context, '/all_alerts');
        break;
      case 4: // Chat
        if (_userRole == 'rescue_team') {
          Navigator.pushNamed(context, '/chat_list');
        } else {
          Navigator.pushNamed(context, '/user_chat_list');
        }
        break;
    }
  }

  void _onFabTapped() {
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
                  icon: Icons.list_alt_outlined,
                  index: 1,
                  label: _userRole == 'rescue_team' ? 'Reports' : 'Alerts'),
              const SizedBox(width: 40),
              // MODIFIED: This now includes the notification badge
              _buildAlertsNavItem(),
              _buildNavItem(
                  icon: Icons.chat_bubble_outline, index: 4, label: 'Chat'),
            ],
          ),
        ),
      ),
    );
  }

  // NEW: A dedicated widget for the Alerts button with a notification badge
  Widget _buildAlertsNavItem() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('alerts').snapshots(),
      builder: (context, snapshot) {
        final alertCount = snapshot.data?.docs.length ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: _selectedIndex == 3
                    ? Colors.white
                    : Colors.white.withOpacity(0.6),
                size: 28,
              ),
              onPressed: () => _onItemTapped(3),
              tooltip: 'Alerts',
            ),
            if (alertCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$alertCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
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
