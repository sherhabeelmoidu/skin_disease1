import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:skin_disease1/booking_screen.dart';
import 'package:skin_disease1/chat_room.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DoctorsMapScreen extends StatefulWidget {
  final Position? userPosition;

  const DoctorsMapScreen({this.userPosition});

  @override
  _DoctorsMapScreenState createState() => _DoctorsMapScreenState();
}

class _DoctorsMapScreenState extends State<DoctorsMapScreen> {
  List<Marker> _markers = <Marker>[];
  List<Marker> _hospitalMarkers = <Marker>[];
  final MapController _mapController = MapController();
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  bool _showHospitals = true;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.userPosition;
    if (_currentPosition != null) {
      _fetchNearbyHospitals(_currentPosition!.latitude, _currentPosition!.longitude);
    } else {
      _getCurrentLocation();
    }
    _loadDoctorMarkers();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        setState(() {
          _currentPosition = position;
          _isLoadingLocation = false;
        });
        _mapController.move(LatLng(position.latitude, position.longitude), 13);
        _loadDoctorMarkers(); 
        _fetchNearbyHospitals(position.latitude, position.longitude);
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _fetchNearbyHospitals(double lat, double lng) async {
    try {
      // Overpass API query to find hospitals and clinics within 5km
      final query = """
        [out:json];
        (
          node["amenity"="hospital"](around:5000, $lat, $lng);
          node["amenity"="clinic"](around:5000, $lat, $lng);
        );
        out body;
      """;

      final url = Uri.parse('https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(query)}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List?;
        
        if (elements == null) return;

        List<Marker> newMarkers = [];
        for (var element in elements) {
          final latNum = element['lat'];
          final lonNum = element['lon'];
          
          if (latNum is! num || lonNum is! num) continue;
          
          final hLat = latNum.toDouble();
          final hLng = lonNum.toDouble();
          final name = element['tags']['name'] ?? 'Hospital/Clinic';
          
          newMarkers.add(
            Marker(
              point: LatLng(hLat, hLng),
              width: 140,
              height: 80,
              child: GestureDetector(
                onTap: () {
                   showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.white,
                    builder: (context) => Container(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_hospital, size: 50, color: Colors.green),
                          SizedBox(height: 10),
                          Text(name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          Text('Public Medical Facility', style: TextStyle(color: Colors.grey)),
                          SizedBox(height: 20),
                          Text('This is a public listing. Not registered with DermaSense.', style: TextStyle(fontSize: 12, color: Colors.orange)),
                        ],
                      ),
                    ),
                  );
                },
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.green)),
                      child: Text(name, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green), overflow: TextOverflow.ellipsis),
                    ),
                    Icon(Icons.local_hospital, color: Colors.green, size: 32),
                  ],
                ),
              ),
            ),
          );
        }
        
        if (mounted) {
          setState(() {
            _hospitalMarkers = newMarkers;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching hospitals: $e');
    }
  }

  void _loadDoctorMarkers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('doctors')
        .where('approval_status', isEqualTo: 'approved')
        .get();
    List<Marker> markers = [];

    // Add user marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          width: 80,
          height: 80,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                child: Text('You', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              Icon(Icons.person_pin_circle, color: Colors.blueAccent, size: 40),
            ],
          ),
        ),
      );
    }

    for (var doc in snapshot.docs) {
      final data = doc.data();
      data['docId'] = doc.id; // Important for booking
      final lat = data['latitude'] as double?;
      final lng = data['longitude'] as double?;

      if (lat != null && lng != null) {
        markers.add(
          Marker(
            point: LatLng(lat, lng),
            width: 160,
            height: 100,
            child: GestureDetector(
              onTap: () {
                _showDoctorSnippet(context, data);
              },
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFF3B9AE1), 
                      borderRadius: BorderRadius.circular(12), 
                      boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3))]
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Dr. ${data['name']}', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                        Text('Skin Specialist', style: TextStyle(color: Colors.white70, fontSize: 9)),
                      ],
                    ),
                  ),
                  Icon(Icons.location_on, color: Color(0xFFE74C3C), size: 36),
                ],
              ),
            ),
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _markers = markers);
    }
  }

  void _showDoctorSnippet(BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: data['profile_image'] != null ? NetworkImage(data['profile_image']) : null,
                  backgroundColor: Color(0xFF3B9AE1).withOpacity(0.1),
                  child: data['profile_image'] == null ? Text(data['name'][0], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF3B9AE1))) : null,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dr. ${data['name']}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                      Text(data['specialization'] ?? 'Dermatologist', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                      SizedBox(height: 4),
                       Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey),
                          Expanded(child: Text(data['place'] ?? 'Clinic', style: TextStyle(color: Colors.grey[600], fontSize: 12), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () { 
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => BookingScreen(doctorData: data, doctorId: data['docId'])));
                    },
                    icon: Icon(Icons.calendar_today, size: 18),
                    label: Text('Book Visit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3B9AE1), 
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF3B9AE1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.chat_bubble_outline, color: Color(0xFF3B9AE1)),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ChatRoom(peerId: data['uid'] ?? data['docId'], peerName: data['name'])));
                    },
                  ),
                ),
              ],
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
        title: Text('Nearby Specialists', style: TextStyle(color: Color(0xFF2C3E50), fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF2C3E50)),
        actions: [
          IconButton(
            icon: Icon(Icons.local_hospital, color: _showHospitals ? Colors.green : Colors.grey),
            onPressed: () => setState(() => _showHospitals = !_showHospitals),
            tooltip: 'Toggle Hospitals',
          ),
          IconButton(
            icon: Icon(Icons.my_location, color: Color(0xFF3B9AE1)),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _currentPosition != null 
              ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
              : LatLng(20.5937, 78.9629), // Default to India center or 0,0
          initialZoom: 13,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.skin_disease1',
          ),
          MarkerLayer(markers: [
            ..._markers,
            if (_showHospitals) ..._hospitalMarkers,
          ]),
        ],
      ),
    );
  }
}
