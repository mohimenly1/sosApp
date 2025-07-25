import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  final LatLng _center = const LatLng(32.8872, 13.1913); // Tripoli
  int _selectedIndex = 1; // Map is selected in bottom nav

  // Sample evacuation points
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _addEvacuationPoints();
    _addSafeRoutes();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _addEvacuationPoints() {
    // Add sample evacuation points
    _markers.add(
      Marker(
        markerId: const MarkerId('evacuation_1'),
        position: const LatLng(32.8900, 13.1950),
        infoWindow: const InfoWindow(
          title: 'Evacuation Center 1',
          snippet: 'Medical assistance available',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );

    _markers.add(
      Marker(
        markerId: const MarkerId('evacuation_2'),
        position: const LatLng(32.8800, 13.1850),
        infoWindow: const InfoWindow(
          title: 'Evacuation Center 2',
          snippet: 'Food and water available',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );

    _markers.add(
      Marker(
        markerId: const MarkerId('danger_1'),
        position: const LatLng(32.8820, 13.2000),
        infoWindow: const InfoWindow(
          title: 'Danger Zone',
          snippet: 'Flooding reported',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
  }

  void _addSafeRoutes() {
    // Add a sample safe route
    _polylines.add(
      const Polyline(
        polylineId: PolylineId('safe_route_1'),
        visible: true,
        points: [
          LatLng(32.8872, 13.1913), // Start point
          LatLng(32.8890, 13.1930),
          LatLng(32.8900, 13.1950), // Evacuation center 1
        ],
        width: 4,
        color: Colors.blue,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/');
    } else if (index == 2) {
      Navigator.pushNamed(context, '/chat');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Safe Routes Map"),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 14.0,
            ),
            myLocationEnabled: true,
            markers: _markers,
            polylines: _polylines,
          ),
          // Map controls overlay
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'locate',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () {
                    // Center map on current location
                    mapController.animateCamera(
                      CameraUpdate.newLatLngZoom(_center, 15),
                    );
                  },
                  child:
                      const Icon(Icons.my_location, color: Colors.deepOrange),
                ),
                const SizedBox(height: 8), // Correct usage
                FloatingActionButton(
                  heroTag: 'zoom_in',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () {
                    mapController.animateCamera(CameraUpdate.zoomIn());
                  },
                  child: const Icon(Icons.add, color: Colors.deepOrange),
                ),
                const SizedBox(height: 8), // Correct usage
                FloatingActionButton(
                  heroTag: 'zoom_out',
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () {
                    mapController.animateCamera(CameraUpdate.zoomOut());
                  },
                  child: const Icon(Icons.remove, color: Colors.deepOrange),
                ),
              ],
            ),
          ),
          // Route info card
          Positioned(
            bottom: 90, // Above the bottom nav
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Nearest Safe Zone',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8), // Correct usage
                    const Text(
                      'Evacuation Center 1',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4), // Correct usage
                    const Text(
                      'Distance: 0.5 km • ETA: 6 min',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16), // Correct usage
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to this route
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Navigate'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.question_mark),
            label: 'Help',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepOrange,
        onTap: _onItemTapped,
      ),
    );
  }
}
