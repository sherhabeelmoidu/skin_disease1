import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:skin_disease1/utils/responsive_helper.dart';

class AdminAppointments extends StatefulWidget {
  const AdminAppointments({Key? key}) : super(key: key);

  @override
  State<AdminAppointments> createState() => _AdminAppointmentsState();
}

class _AdminAppointmentsState extends State<AdminAppointments> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: ResponsiveHelper.getMaxWidth(context),
              ),
              child: const Text(
                'Appointments Management',
                style: TextStyle(
                  color: Color(0xFF2C3E50),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: ResponsiveHelper.getMaxWidth(context),
                ),
                child: const TabBar(
                  labelColor: Color(0xFF3B9AE1),
                  unselectedLabelColor: Color(0xFF7F8C8D),
                  indicatorColor: Color(0xFF3B9AE1),
                  tabs: [
                    Tab(text: 'Upcoming'),
                    Tab(text: 'Completed/Cancelled'),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: ResponsiveHelper.getMaxWidth(context),
            ),
            child: TabBarView(
              children: [
                _buildAppointmentList(['pending', 'confirmed']),
                _buildAppointmentList(['completed', 'cancelled']),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentList(List<String> statuses) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('appointments').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(child: Text('Error: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No appointments in this category'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildAdminAppointmentCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildAdminAppointmentCard(String docId, Map<String, dynamic> data) {
    final status = data['status'] ?? 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Patient: ${data['userName'] ?? 'Unknown'}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              _buildStatusLabel(status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Doctor: Dr. ${data['doctorName']}',
            style: const TextStyle(color: Color(0xFF3B9AE1), fontSize: 14),
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(data['date'] ?? '', style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(data['time'] ?? '', style: const TextStyle(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),

          // Action Buttons
          if (status == 'pending')
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateStatus(docId, 'cancelled'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus(docId, 'confirmed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),

          if (status == 'confirmed')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showCompletionDialog(docId, data),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Complete Visit & Give Treatment'),
              ),
            ),

          if (status == 'completed') ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _showProgressReviewDialog(docId),
              icon: const Icon(Icons.rate_review),
              label: const Text('Review Progress Updates'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _updateStatus(String docId, String newStatus) async {
    await _firestore.collection('appointments').doc(docId).update({
      'status': newStatus,
    });
  }

  void _showCompletionDialog(String docId, Map<String, dynamic> data) {
    final treatmentController = TextEditingController();
    final tipsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Consultation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: treatmentController,
              decoration: const InputDecoration(labelText: 'Treatment Given'),
              maxLines: 2,
            ),
            TextField(
              controller: tipsController,
              decoration: const InputDecoration(labelText: 'Doctor Tips'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _firestore.collection('appointments').doc(docId).update({
                'status': 'completed',
                'treatment': treatmentController.text,
                'doctorTips': tipsController.text,
              });
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showProgressReviewDialog(String appointmentId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Patient Progress Updates',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('appointments')
                    .doc(appointmentId)
                    .collection('progress_updates')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final update = doc.data() as Map<String, dynamic>;
                      return _buildProgressUpdateItem(
                        appointmentId,
                        doc.id,
                        update,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressUpdateItem(
    String appointmentId,
    String updateId,
    Map<String, dynamic> update,
  ) {
    final feedbackController = TextEditingController(
      text: update['doctorFeedback'] ?? '',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(update['notes'] ?? '', style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 12),
          TextField(
            controller: feedbackController,
            decoration: InputDecoration(
              hintText: 'Give feedback or tips...',
              suffixIcon: IconButton(
                icon: const Icon(Icons.send, color: Colors.blue),
                onPressed: () async {
                  await _firestore
                      .collection('appointments')
                      .doc(appointmentId)
                      .collection('progress_updates')
                      .doc(updateId)
                      .update({'doctorFeedback': feedbackController.text});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feedback sent')),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusLabel(String status) {
    Color color;
    switch (status) {
      case 'confirmed':
        color = Colors.blue;
        break;
      case 'completed':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
