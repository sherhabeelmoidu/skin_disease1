import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skin_disease1/login.dart';
import 'package:skin_disease1/chat_list.dart';

class DoctorDashboard extends StatefulWidget {
  @override
  _DoctorDashboardState createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  int _selectedIndex = 0;
  final user = FirebaseAuth.instance.currentUser;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      _DoctorOverview(),
      _DoctorAppointments(),
      ChatList(),
      _DoctorSettings(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Doctor Dashboard', style: TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginApp()));
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        selectedItemColor: Color(0xFF3B9AE1),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_outlined), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}

class _DoctorOverview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Analytics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          Row(
            children: [
              _buildStatCard('Pending', Icons.timer_outlined, Colors.orange, 'appointments', 'pending', uid!),
              SizedBox(width: 16),
              _buildStatCard('Confirmed', Icons.check_circle_outline, Colors.blue, 'appointments', 'confirmed', uid),
            ],
          ),
          SizedBox(height: 16),
          _buildStatCard('Completed', Icons.done_all, Colors.green, 'appointments', 'completed', uid, isFullWidth: true),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, IconData icon, Color color, String collection, String status, String uid, {bool isFullWidth = false}) {
    return Expanded(
      flex: isFullWidth ? 2 : 1,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(collection)
            .where('doctorId', isEqualTo: uid)
            .where('status', isEqualTo: status)
            .snapshots(),
        builder: (context, snapshot) {
          int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
          return Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 28),
                SizedBox(height: 12),
                Text(count.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(label, style: TextStyle(color: Color(0xFF7F8C8D))),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DoctorAppointments extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return Center(child: Text('No bookings found'));

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final docId = snapshot.data!.docs[index].id;
            return _buildAppointmentCard(context, docId, data);
          },
        );
      },
    );
  }

  Widget _buildAppointmentCard(BuildContext context, String docId, Map<String, dynamic> data) {
    final status = data['status'] ?? 'pending';
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(data['userName'] ?? 'Patient', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              _buildStatusChip(status),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              SizedBox(width: 4),
              Text('${data['date']} | ${data['time']}', style: TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
          if (status == 'pending') ...[
            Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _update(docId, 'cancelled'),
                    child: Text('Cancel'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _update(docId, 'confirmed'),
                    child: Text('Confirm'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          ],
          if (status == 'confirmed') ...[
            Divider(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showCompleteDialog(context, docId),
                child: Text('Complete & Give Treatment'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _update(String id, String status) {
    FirebaseFirestore.instance.collection('appointments').doc(id).update({'status': status});
  }

  void _showCompleteDialog(BuildContext context, String id) {
    final t = TextEditingController();
    final tips = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Complete Consultation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: t, decoration: InputDecoration(labelText: 'Treatment')),
            TextField(controller: tips, decoration: InputDecoration(labelText: 'Health Tips')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('appointments').doc(id).update({
                'status': 'completed',
                'treatment': t.text,
                'doctorTips': tips.text,
              });
              Navigator.pop(context);
            },
            child: Text('Complete'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color c = Colors.orange;
    if (status == 'confirmed') c = Colors.blue;
    if (status == 'completed') c = Colors.green;
    if (status == 'cancelled') c = Colors.red;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _DoctorSettings extends StatefulWidget {
  @override
  State<_DoctorSettings> createState() => _DoctorSettingsState();
}

class _DoctorSettingsState extends State<_DoctorSettings> {
  bool _isAcceptingValue = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          CircleAvatar(radius: 50, backgroundColor: Color(0xFF3B9AE1), child: Icon(Icons.person, size: 50, color: Colors.white)),
          SizedBox(height: 20),
          Text(FirebaseAuth.instance.currentUser?.displayName ?? 'Doctor Name', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 32),
          
          // Slot Availability Toggle
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Accepting Bookings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Turn off to stop new appointments', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                Switch(
                  value: _isAcceptingValue,
                  onChanged: (v) => setState(() => _isAcceptingValue = v),
                  activeColor: Color(0xFF3B9AE1),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          _buildOption(Icons.edit_note, 'Edit Profile Details'),
          _buildOption(Icons.access_time, 'Manage Time Slots'),
          _buildOption(Icons.history, 'Consultation History'),
          _buildOption(Icons.help_outline, 'Help & Support'),
        ],
      ),
    );
  }

  Widget _buildOption(IconData icon, String title) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Color(0xFF3B9AE1)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
        trailing: Icon(Icons.chevron_right, size: 20),
        onTap: () {},
      ),
    );
  }
}
