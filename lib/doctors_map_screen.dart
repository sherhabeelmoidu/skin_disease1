import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class DoctorsMapScreen extends StatefulWidget {
  final Position? userPosition;

  const DoctorsMapScreen({this.userPosition});

  @override
  _DoctorsMapScreenState createState() => _DoctorsMapScreenState();
}

class _DoctorsMapScreenState extends State<DoctorsMapScreen> {
  List<Marker> _markers = [];
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadDoctorMarkers();
  }

  void _loadDoctorMarkers() async {
    final snapshot = await FirebaseFirestore.instance.collection('doctors').get();
    List<Marker> markers = [];

    // Add user marker
    if (widget.userPosition != null) {
      markers.add(
        Marker(
          point: LatLng(widget.userPosition!.latitude, widget.userPosition!.longitude),
          width: 80,
          height: 80,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                child: Text('You', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
            ],
          ),
        ),
      );
    }

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final lat = data['latitude'] as double?;
      final lng = data['longitude'] as double?;

      if (lat != null && lng != null) {
        markers.add(
          Marker(
            point: LatLng(lat, lng),
            width: 150,
            height: 80,
            child: GestureDetector(
              onTap: () {
                _showDoctorSnippet(context, data);
              },
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Color(0xFF3B9AE1), borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                    child: Text('Dr. ${data['name']}', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  ),
                  Icon(Icons.location_on, color: Colors.red, size: 30),
                ],
              ),
            ),
          ),
        );
      }
    }

    setState(() => _markers = markers);
  }

  void _showDoctorSnippet(BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Dr. ${data['name']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(data['specialization'] ?? 'Dermatologist', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('View Full Profile'),
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF3B9AE1), foregroundColor: Colors.white),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nearby Doctors (Free Map)', style: TextStyle(color: Color(0xFF2C3E50), fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF2C3E50)),
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: LatLng(
            widget.userPosition?.latitude ?? 0,
            widget.userPosition?.longitude ?? 0,
          ),
          initialZoom: 13,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.skin_disease1',
          ),
          MarkerLayer(markers: _markers),
        ],
      ),
    );
  }
}
