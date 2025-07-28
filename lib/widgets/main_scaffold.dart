import 'package:flutter/material.dart';

class MainScaffold extends StatefulWidget {
  final Widget body;
  const MainScaffold({super.key, required this.body});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 2; // Default to the home/SOS screen

  // This function handles taps on the bottom navigation bar items
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Add navigation logic here based on index
    // For example:
    // if (index == 0) Navigator.pushNamed(context, '/map');
    // if (index == 4) Navigator.pushNamed(context, '/chat');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.body,
      // The central floating action button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Handle SOS action
          Navigator.pushNamed(context, '/sos');
        },
        backgroundColor: Colors.white,
        elevation: 4.0,
        shape: const CircleBorder(),
        child: const Text(
          'SOS',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // The custom bottom navigation bar
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

  // Helper widget to build each navigation item
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
