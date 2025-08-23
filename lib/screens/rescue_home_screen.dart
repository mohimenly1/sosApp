import 'package:flutter/material.dart';
import 'package:resq_track4/widgets/home_grid_button.dart';
import 'package:resq_track4/widgets/main_scaffold.dart';
import 'package:easy_localization/easy_localization.dart';

class RescueHomeScreen extends StatelessWidget {
  const RescueHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      body: Scaffold(
        appBar: AppBar(
          title: Text("rescue_dashboard".tr()),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              onPressed: () => Navigator.pushNamed(context, '/settings'),
              tooltip: 'settings'.tr(),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              GridView.count(
                padding: const EdgeInsets.all(16.0),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  HomeGridButton(
                    icon: Icons.group_add_outlined,
                    label: "manage_teams".tr(),
                    onTap: () => Navigator.pushNamed(context, '/manage_teams'),
                  ),
                  HomeGridButton(
                    icon: Icons.warning_amber_rounded,
                    label: "active_reports".tr(),
                    onTap: () =>
                        Navigator.pushNamed(context, '/active_reports'),
                  ),
                  HomeGridButton(
                    icon: Icons.map_outlined,
                    label: "live_map".tr(),
                    onTap: () => Navigator.pushNamed(context, '/user_map'),
                  ),
                  HomeGridButton(
                    icon: Icons.smart_toy_outlined,
                    label: "ai_assistant".tr(),
                    onTap: () => Navigator.pushNamed(context, '/chat'),
                  ),
                  HomeGridButton(
                    icon: Icons.chat_bubble_outline,
                    label: "chat_box".tr(),
                    onTap: () => Navigator.pushNamed(context, '/chat_list'),
                  ),
                  HomeGridButton(
                    icon: Icons.cloud_outlined,
                    label: "weather".tr(),
                    onTap: () => Navigator.pushNamed(context, '/weather'),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_location_alt_outlined,
                        color: Colors.white),
                    label: Text("add_shelters".tr(),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16)),
                    onPressed: () =>
                        Navigator.pushNamed(context, '/add_shelter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A2342),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
