import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skin_disease1/chat_list.dart';
import 'package:skin_disease1/notification_service.dart';
import 'package:skin_disease1/notifications_screen.dart';
import 'package:skin_disease1/main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skin_disease1/doctor_slots_screen.dart';
import 'package:skin_disease1/doctor_professional_details_screen.dart';
import 'package:skin_disease1/doctor_change_password_screen.dart';
import 'package:skin_disease1/doctor_support_center_screen.dart';

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
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3B9AE1), Color(0xFF2C3E50)],
            ),
          ),
        ),
        title: Text(
          'Doctor Portal',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const AuthWrapper()),
                (route) => false,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF3B9AE1).withOpacity(0.1),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard, color: Color(0xFF3B9AE1)), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today, color: Color(0xFF3B9AE1)), label: 'Bookings'),
            NavigationDestination(icon: Icon(Icons.chat_outlined), selectedIcon: Icon(Icons.chat, color: Color(0xFF3B9AE1)), label: 'Messages'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings, color: Color(0xFF3B9AE1)), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}

class _DoctorOverview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Practice Analytics',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Monitor your daily performance and patient flow.',
            style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 32),
          
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              _buildStatCard('Pending', Icons.timer_outlined, const Color(0xFFF59E0B), 'appointments', 'pending', uid!),
              _buildStatCard('Confirmed', Icons.check_circle_outline, const Color(0xFF3B82F6), 'appointments', 'confirmed', uid),
              _buildStatCard('Completed', Icons.done_all, const Color(0xFF10B981), 'appointments', 'completed', uid),
              _buildStatCard('Cancelled', Icons.cancel_outlined, const Color(0xFFEF4444), 'appointments', 'cancelled', uid),
            ],
          ),
          
          const SizedBox(height: 32),
          _buildQuickActionCard(context),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, IconData icon, Color color, String collection, String status, String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .where('doctorId', isEqualTo: uid)
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
                Text(
                  count.toString(),
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3E50),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bolt, color: Colors.yellow, size: 32),
          const SizedBox(height: 16),
          Text(
            'Manage Your Availability',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep your schedule updated to help patients book slots correctly.',
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DoctorSlotsScreen())),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF2C3E50),
            ),
            child: const Text('Update Schedule'),
          ),
        ],
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
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('No bookings found', style: GoogleFonts.outfit(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF3B9AE1).withOpacity(0.1),
                  child: const Icon(Icons.person_outline, color: Color(0xFF3B9AE1)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['userName'] ?? 'Patient',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '${data['date']} at ${data['time']}',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(status),
              ],
            ),
            if (status == 'pending') ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _update(docId, 'cancelled', data['userId'], data['doctorName']),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _update(docId, 'confirmed', data['userId'], data['doctorName']),
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ],
            if (status == 'confirmed') ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showCompleteDialog(context, docId, data['userId'], data['doctorName']),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                  child: const Text('Complete Consultation'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _update(String id, String status, String userId, String? doctorName) async {
    final docRef = FirebaseFirestore.instance.collection('appointments').doc(id);
    final docSnap = await docRef.get();
    final data = docSnap.data() as Map<String, dynamic>?;

    await docRef.update({'status': status});
    
    // If cancelled, free up the slot
    if (status == 'cancelled' && data != null && data['slotId'] != null) {
      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('slots')
          .doc(data['slotId'])
          .update({'isBooked': false, 'bookedBy': null});
    }

    await NotificationService.sendNotification(
      userId: userId,
      title: 'Appointment $status',
      message: 'Your appointment with Dr. ${doctorName ?? 'Doctor'} has been $status.',
      type: 'appointment_update',
    );
  }

  void _showCompleteDialog(BuildContext context, String id, String userId, String? doctorName) {
    final t = TextEditingController();
    final tips = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Consultation Report', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: t, decoration: const InputDecoration(labelText: 'Diagnosis & Treatment')),
            const SizedBox(height: 16),
            TextField(controller: tips, decoration: const InputDecoration(labelText: 'Patient Guidance/Tips')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('appointments').doc(id).update({
                'status': 'completed',
                'treatment': t.text,
                'doctorTips': tips.text,
              });
              
              await NotificationService.sendNotification(
                userId: userId,
                title: 'Consultation Completed',
                message: 'Dr. ${doctorName ?? 'Doctor'} has completed your consultation and added treatment notes.',
                type: 'appointment_completed',
              );
              
              Navigator.pop(context);
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color c = const Color(0xFFF59E0B);
    if (status == 'confirmed') c = const Color(0xFF3B82F6);
    if (status == 'completed') c = const Color(0xFF10B981);
    if (status == 'cancelled') c = const Color(0xFFEF4444);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.outfit(color: c, fontSize: 10, fontWeight: FontWeight.bold),
      ),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Color(0xFF3B9AE1),
            child: Icon(Icons.medical_services_outlined, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            FirebaseAuth.instance.currentUser?.displayName ?? 'Doctor Profile',
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Booking Status', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Text('Receive new patient requests', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  Switch(
                    value: _isAcceptingValue,
                    onChanged: (v) => setState(() => _isAcceptingValue = v),
                    activeColor: const Color(0xFF3B9AE1),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          _buildOption(Icons.edit_note_outlined, 'Professional Details'),
          _buildOption(Icons.access_time_outlined, 'Working Hours'),
          _buildOption(Icons.lock_reset_outlined, 'Change Password'),
          _buildOption(Icons.help_outline, 'Support Center'),
        ],
      ),
    );
  }

  Widget _buildOption(IconData icon, String title) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF3B9AE1)),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right, size: 20, color: Color(0xFF94A3B8)),
        onTap: () {
          if (title == 'Working Hours') {
             Navigator.push(context, MaterialPageRoute(builder: (context) => const DoctorSlotsScreen()));
          } else if (title == 'Professional Details') {
             Navigator.push(context, MaterialPageRoute(builder: (context) => const DoctorProfessionalDetailsScreen()));
          } else if (title == 'Change Password') {
             Navigator.push(context, MaterialPageRoute(builder: (context) => const DoctorChangePasswordScreen()));
          } else if (title == 'Support Center') {
             Navigator.push(context, MaterialPageRoute(builder: (context) => const DoctorSupportCenterScreen()));
          }
        },
      ),
    );
  }
}
