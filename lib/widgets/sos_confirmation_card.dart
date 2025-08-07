import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../screens/sos_report_map_screen.dart'; // 1. Import the new full-screen page

class SosConfirmationCard extends StatefulWidget {
  const SosConfirmationCard({super.key});

  @override
  State<SosConfirmationCard> createState() => _SosConfirmationCardState();
}

class _SosConfirmationCardState extends State<SosConfirmationCard> {
  bool _isDeterminingLocation = false;

  Future<void> _determinePositionAndNavigate() async {
    setState(() => _isDeterminingLocation = true);

    try {
      // Get the user's current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        // 2. Navigate to the new full-screen page with the location data
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SosReportMapScreen(initialPosition: position),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get location: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeterminingLocation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Do you want to send\na distress signal?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A2342),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _isDeterminingLocation
                    ? null
                    : _determinePositionAndNavigate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A2342),
                  minimumSize: const Size(100, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isDeterminingLocation
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Yes',
                        style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A2342),
                  minimumSize: const Size(100, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('No',
                    style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
