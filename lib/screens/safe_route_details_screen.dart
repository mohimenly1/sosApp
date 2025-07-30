import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SafeRouteDetailsScreen extends StatelessWidget {
  final String routeId;
  const SafeRouteDetailsScreen({super.key, required this.routeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safe Evacuation Route'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('evacuation_routes')
            .doc(routeId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
                child: Text('Route details could not be loaded.'));
          }

          final routeData = snapshot.data!.data() as Map<String, dynamic>;
          final startPointGeo = routeData['startPoint'] as GeoPoint;
          final endPointGeo = routeData['endPoint'] as GeoPoint;
          final startPoint =
              LatLng(startPointGeo.latitude, startPointGeo.longitude);
          final endPoint = LatLng(endPointGeo.latitude, endPointGeo.longitude);

          return FlutterMap(
            options: MapOptions(
              initialCenter: startPoint,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [startPoint, endPoint],
                    strokeWidth: 5.0,
                    color: Colors.green,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: startPoint,
                    width: 100,
                    height: 80,
                    child: const Column(children: [
                      Icon(Icons.location_on, color: Colors.blue, size: 40),
                      Text('Start Here')
                    ]),
                  ),
                  Marker(
                    point: endPoint,
                    width: 100,
                    height: 80,
                    child: const Column(children: [
                      Icon(Icons.shield, color: Colors.green, size: 40),
                      Text('Safe Shelter')
                    ]),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
