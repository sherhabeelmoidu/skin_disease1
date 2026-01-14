import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:skin_disease1/booking_screen.dart';
import 'package:skin_disease1/chat_room.dart';
import 'package:skin_disease1/appointments_screen.dart';
import 'package:skin_disease1/doctors_map_screen.dart';

class DoctorsScreen extends StatefulWidget {
  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Position? _userPosition;
  bool _sortByDistance = false;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }


  double _calculateDistance(double? lat, double? lng) {
    if (_userPosition == null || lat == null || lng == null) return -1;
    return Geolocator.distanceBetween(
      _userPosition!.latitude,
      _userPosition!.longitude,
      lat,
      lng,
    ) / 1000; // km
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Our Doctors', style: TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined, color: Color(0xFF3B9AE1)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DoctorsMapScreen(userPosition: _userPosition))),
          ),
          IconButton(
            icon: const Icon(Icons.event_note, color: Colors.grey),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AppointmentsScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _getUserLocation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: _sortByDistance ? const Color(0xFF3B9AE1) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _sortByDistance ? const Color(0xFF3B9AE1) : Colors.transparent),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.near_me, 
                            size: 18, 
                            color: _sortByDistance ? Colors.white : const Color(0xFF64748B)
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Find Nearest',
                            style: TextStyle(
                              color: _sortByDistance ? Colors.white : const Color(0xFF64748B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _sortByDistance = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: !_sortByDistance ? const Color(0xFF3B9AE1) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: !_sortByDistance ? const Color(0xFF3B9AE1) : Colors.transparent),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.list, 
                            size: 18, 
                            color: !_sortByDistance ? Colors.white : const Color(0xFF64748B)
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Show All',
                            style: TextStyle(
                              color: !_sortByDistance ? Colors.white : const Color(0xFF64748B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('doctors')
                  .where('approval_status', isEqualTo: 'approved')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                var docs = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  data['docId'] = doc.id;
                  data['distance'] = _calculateDistance(data['latitude'], data['longitude']);
                  return data;
                }).toList();

                if (_sortByDistance && _userPosition != null) {
                  docs.sort((a, b) {
                    if (a['distance'] == -1) return 1;
                    if (b['distance'] == -1) return -1;
                    return a['distance'].compareTo(b['distance']);
                  });
                }

                if (docs.isEmpty) {
                  return const Center(child: Text('No approved doctors found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doctorData = docs[index];
                    return _buildDoctorCard(doctorData);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Override to toggle sort
  @override
  Future<void> _getUserLocation() async {
    setState(() => _sortByDistance = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        setState(() => _userPosition = position);
      } else {
        setState(() => _sortByDistance = false); // Revert if permission denied
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() => _sortByDistance = false);
    }
  }

  Widget _buildDoctorCard(Map<String, dynamic> data) {
    final dist = data['distance'] as double;
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: InkWell(
        onTap: () => _showDoctorDetails(context, data),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Color(0xFF3B9AE1).withOpacity(0.1),
                child: Text(data['name'][0].toUpperCase(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF3B9AE1))),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dr. ${data['name']}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    Text(data['specialization'] ?? 'Dermatologist', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Color(0xFF3B9AE1)),
                        SizedBox(width: 4),
                        Text(dist == -1 ? 'Location unknown' : '${dist.toStringAsFixed(1)} km away', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.chat_bubble_outline, color: Color(0xFF3B9AE1)),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatRoom(peerId: data['uid'] ?? data['docId'], peerName: data['name']))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDoctorDetails(BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              CircleAvatar(radius: 50, backgroundColor: Color(0xFF3B9AE1).withOpacity(0.1), child: Text(data['name'][0], style: TextStyle(fontSize: 40))),
              SizedBox(height: 16),
              Text('Dr. ${data['name']}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(data['qualification'] ?? '', style: TextStyle(color: Colors.grey)),
              SizedBox(height: 24),
              _buildInfoRow(Icons.work, 'Experience', '${data['years_of_experience']} years'),
              _buildInfoRow(Icons.location_city, 'Clinic', data['place'] ?? 'N/A'),
              _buildInfoRow(Icons.map_outlined, 'Address', data['address'] ?? 'N/A'),
              SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BookingScreen(doctorData: data, doctorId: data['docId']))),
                      icon: Icon(Icons.calendar_month),
                      label: Text('Book Now'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(vertical: 14)),
                    ),
                  ),
                  SizedBox(width: 12),
                  CircleAvatar(
                    backgroundColor: Color(0xFF3B9AE1),
                    child: IconButton(icon: Icon(Icons.chat, color: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatRoom(peerId: data['uid'] ?? data['docId'], peerName: data['name'])))),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Color(0xFF3B9AE1)),
          SizedBox(width: 12),
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, style: TextStyle(color: Colors.grey[700]))),
        ],
      ),
    );
  }
}
