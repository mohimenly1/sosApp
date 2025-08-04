import 'package:flutter/material.dart';
import 'package:resq_track4/widgets/home_grid_button.dart'; // Reusing our handy button widget
import 'package:resq_track4/widgets/main_scaffold.dart';

class RescueHomeScreen extends StatelessWidget {
  const RescueHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The main scaffold provides the consistent bottom navigation bar
    return MainScaffold(
      body: Scaffold(
        appBar: AppBar(
          title: const Text('Rescue Dashboard'),
          automaticallyImplyLeading: false, // Removes the back button
          // NEW: Added the settings icon to the AppBar
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
              tooltip: 'Settings',
            ),
          ],
        ),
        body: GridView.count(
          padding: const EdgeInsets.all(16.0),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            HomeGridButton(
              icon: Icons.group_add_outlined,
              label: 'Manage Teams',
              onTap: () {
                Navigator.pushNamed(context, '/manage_teams');
              },
            ),
            HomeGridButton(
              icon: Icons.warning_amber_rounded,
              label: 'Active Reports',
              onTap: () {
                Navigator.pushNamed(context, '/active_reports');
              },
            ),
            HomeGridButton(
              icon: Icons.map_outlined,
              label: 'Live Map',
              onTap: () {
                Navigator.pushNamed(context, '/user_map');
              },
            ),
            HomeGridButton(
              icon: Icons.smart_toy_outlined,
              label: 'AI Assistant',
              onTap: () {
                Navigator.pushNamed(context, '/chat');
              },
            ),
            HomeGridButton(
              icon: Icons.chat_bubble_outline,
              label: 'Chat Box',
              onTap: () => Navigator.pushNamed(context, '/chat_list'),
            ),
            HomeGridButton(
              icon: Icons.cloud_outlined,
              label: 'Weather',
              onTap: () {
                Navigator.pushNamed(context, '/weather');
              },
            ),
          ],
        ),
      ),
    );
  }
}
