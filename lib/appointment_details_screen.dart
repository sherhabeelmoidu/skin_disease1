import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final String appointmentId;
  final Map<String, dynamic> appointmentData;

  const AppointmentDetailsScreen({
    Key? key,
    required this.appointmentId,
    required this.appointmentData,
  }) : super(key: key);

  @override
  State<AppointmentDetailsScreen> createState() => _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  final TextEditingController _progressController = TextEditingController();
  bool _isSubmittingProgress = false;

  Future<void> _addProgressUpdate() async {
    if (_progressController.text.trim().isEmpty) return;

    setState(() {
      _isSubmittingProgress = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .collection('progress_updates')
          .add({
        'notes': _progressController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'updated_by': 'user',
      });

      _progressController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progress update added')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add update: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingProgress = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.appointmentData['status'] ?? 'pending';
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Appointment Details',
          style: TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            _buildInfoCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Booking Status', style: TextStyle(color: Color(0xFF7F8C8D))),
                      _buildStatusLabel(status),
                    ],
                  ),
                  const Divider(height: 32),
                  _buildDetailRow(Icons.person, 'Doctor', 'Dr. ${widget.appointmentData['doctorName']}'),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.calendar_month, 'Date', widget.appointmentData['date'] ?? 'N/A'),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.access_time, 'Time', widget.appointmentData['time'] ?? 'N/A'),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.location_on, 'Clinic', widget.appointmentData['clinicAddress'] ?? 'Physical Clinic'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Treatment Section (If completed)
            if (status == 'completed' || widget.appointmentData['treatment'] != null) ...[
              const Text(
                'Prescribed Treatment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                color: Colors.green.withOpacity(0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.appointmentData['treatment'] ?? 'Medication and follow-up prescribed during visit.',
                      style: const TextStyle(fontSize: 15, color: Color(0xFF2C3E50)),
                    ),
                    if (widget.appointmentData['doctorTips'] != null) ...[
                      const Divider(height: 32),
                      const Text(
                        'Doctor\'s Tips:',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.appointmentData['doctorTips'],
                        style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            // User Progress Updates Section
            if (status == 'completed') ...[
              const Text(
                'My Progress Updates',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
              ),
              const SizedBox(height: 16),
              
              // Add Progress Field
              _buildInfoCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _progressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'How is your skin condition today?',
                        border: InputBorder.none,
                      ),
                    ),
                    const Divider(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: _isSubmittingProgress ? null : _addProgressUpdate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B9AE1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: _isSubmittingProgress 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Update Progress', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Progress History
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('appointments')
                    .doc(widget.appointmentId)
                    .collection('progress_updates')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: Text('No updates yet. Keep your doctor informed!', style: TextStyle(color: Colors.grey))),
                    );
                  }

                  return Column(
                    children: snapshot.data!.docs.map((doc) {
                      final update = doc.data() as Map<String, dynamic>;
                      final timestamp = update['timestamp'] as Timestamp?;
                      final date = timestamp != null ? DateFormat('MMM d, h:mm a').format(timestamp.toDate()) : 'Recently';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                if (update['doctorFeedback'] != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                    child: const Text('Doctor reviewed', style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(update['notes'] ?? '', style: const TextStyle(fontSize: 14)),
                            if (update['doctorFeedback'] != null) ...[
                              const Divider(),
                              Row(
                                children: [
                                  const Icon(Icons.reply, size: 14, color: Colors.blue),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Doctor: ${update['doctorFeedback']}',
                                      style: const TextStyle(fontSize: 13, color: Colors.blue, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
            
            if (status == 'pending') ...[
              const SizedBox(height: 20),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    // TODO: Implementation for cancelling
                  },
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                  label: const Text('Cancel Appointment', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required Widget child, Color? color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (color == null)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF3B9AE1)),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF7F8C8D))),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusLabel(String status) {
    Color color;
    switch (status) {
      case 'confirmed': color = Colors.blue; break;
      case 'completed': color = Colors.green; break;
      case 'cancelled': color = Colors.red; break;
      default: color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
