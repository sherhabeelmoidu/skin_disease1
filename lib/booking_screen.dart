import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:skin_disease1/notification_service.dart';
import 'package:google_fonts/google_fonts.dart';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> doctorData;
  final String doctorId;

  const BookingScreen({
    Key? key,
    required this.doctorData,
    required this.doctorId,
  }) : super(key: key);

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _selectedDate;
  final TextEditingController _notesController = TextEditingController();
  bool _isBooking = false;
  String? _selectedSlotId;
  String? _selectedSlotTime;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3B9AE1),
              onPrimary: Colors.white,
              onSurface: Color(0xFF2C3E50),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Time selection is now handled by the slot grid

  Future<void> _bookAppointment() async {
    if (_selectedDate == null || _selectedSlotId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and an available time slot')),
      );
      return;
    }

    setState(() {
      _isBooking = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Get user name
      final userDoc = await FirebaseFirestore.instance.collection('user').doc(user.uid).get();
      final userName = userDoc.data()?['name'] ?? 'User';

      final appointmentData = {
        'userId': user.uid,
        'userName': userName,
        'doctorId': widget.doctorId,
        'doctorName': widget.doctorData['name'],
        'designation': widget.doctorData['designation'],
        'clinicAddress': widget.doctorData['address'],
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'time': _selectedSlotTime!,
        'slotId': _selectedSlotId,
        'notes': _notesController.text.trim(),
        'status': 'pending', 
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'offline', 
      };

      // Use transaction to ensure slot availability
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentReference slotRef = FirebaseFirestore.instance
            .collection('doctors')
            .doc(widget.doctorId)
            .collection('slots')
            .doc(_selectedSlotId);

        DocumentSnapshot slotSnap = await transaction.get(slotRef);

        if (!slotSnap.exists || (slotSnap.data() as Map<String, dynamic>)['isBooked'] == true) {
          throw Exception('This slot has already been booked. Please select another slot.');
        }

        // Add appointment
        DocumentReference appRef = FirebaseFirestore.instance.collection('appointments').doc();
        transaction.set(appRef, appointmentData);

        // Mark slot as booked
        transaction.update(slotRef, {
          'isBooked': true,
          'bookedBy': user.uid,
        });
      });

      // Notify the doctor
      if (widget.doctorData['uid'] != null) {
        await NotificationService.sendNotification(
          userId: widget.doctorData['uid'],
          title: 'New Appointment Request',
          message: 'You have a new appointment request from ${appointmentData['userName']} for ${appointmentData['date']}.',
          type: 'new_appointment',
        );
      }

      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Icon(Icons.check_circle, color: Colors.green, size: 64),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Appointment Requested!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your offline consultation with Dr. ${widget.doctorData['name']} is being processed.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to doctor list
              },
              child: const Text('OK', style: TextStyle(color: Color(0xFF3B9AE1), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Book Appointment',
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
            // Doctor Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                   Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3B9AE1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (widget.doctorData['name'] ?? 'D')[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dr. ${widget.doctorData['name']}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        Text(
                          widget.doctorData['designation'] ?? '',
                          style: const TextStyle(color: Color(0xFF7F8C8D)),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Color(0xFF3B9AE1)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.doctorData['place'] ?? 'N/A',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF95A5A6)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Text(
              'Select Date & Time',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 16),

            // Date Picker
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _selectedDate != null ? const Color(0xFF3B9AE1) : Colors.transparent),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF3B9AE1)),
                    const SizedBox(width: 16),
                    Text(
                      _selectedDate == null 
                          ? 'Select Appointment Date' 
                          : DateFormat('EEEE, d MMMM yyyy').format(_selectedDate!),
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedDate == null ? const Color(0xFF7F8C8D) : const Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (_selectedDate != null) ...[
              Text(
                'Available Slots',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('doctors')
                    .doc(widget.doctorId)
                    .collection('slots')
                    .where('date', isEqualTo: DateFormat('yyyy-MM-dd').format(_selectedDate!))
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                    );
                  }

                  // Helper to parse time string like "09:00 AM" into a comparison value
                  DateTime _parseTime(String timeStr) {
                    try {
                      return DateFormat('hh:mm a').parse(timeStr);
                    } catch (e) {
                      return DateTime(2000); // fallback
                    }
                  }

                  final now = DateTime.now();
                  final isToday = _selectedDate != null && 
                      _selectedDate!.year == now.year && 
                      _selectedDate!.month == now.month && 
                      _selectedDate!.day == now.day;

                  final docs = snapshot.data?.docs ?? [];
                  
                  // Sort slots by actual time in memory
                  final sortedDocs = List<QueryDocumentSnapshot>.from(docs);
                  sortedDocs.sort((a, b) {
                    final aTimeStr = (a.data() as Map<String, dynamic>)['time'] ?? '';
                    final bTimeStr = (b.data() as Map<String, dynamic>)['time'] ?? '';
                    return _parseTime(aTimeStr).compareTo(_parseTime(bTimeStr));
                  });

                  // Filter for available and FUTURE slots if today
                  // Filter for FUTURE slots if today, including booked ones
                  final visibleDocs = sortedDocs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    
                    if (isToday) {
                      final slotTime = _parseTime(data['time']);
                      // Combine today's date with slot time for accurate comparison
                      final fullSlotTime = DateTime(
                        now.year, now.month, now.day,
                        slotTime.hour, slotTime.minute
                      );
                      return fullSlotTime.isAfter(now);
                    }
                    return true;
                  }).toList();

                  if (visibleDocs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.2)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.event_busy, color: Colors.orange),
                          SizedBox(height: 8),
                          Text(
                            'No slots found for this date.',
                            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Please try selecting another date.',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2.2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: visibleDocs.length,
                    itemBuilder: (context, index) {
                      final slot = visibleDocs[index].data() as Map<String, dynamic>;
                      final slotId = visibleDocs[index].id;
                      final bool isBooked = slot['isBooked'] == true;
                      final isSelected = _selectedSlotId == slotId;

                      return InkWell(
                        onTap: isBooked ? null : () {
                          setState(() {
                            _selectedSlotId = slotId;
                            _selectedSlotTime = slot['time'];
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isBooked 
                                ? Colors.grey[100] 
                                : (isSelected ? const Color(0xFF3B9AE1) : Colors.white),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isBooked 
                                  ? Colors.grey[300]! 
                                  : (isSelected ? const Color(0xFF3B9AE1) : const Color(0xFFE2E8F0)),
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  slot['time'],
                                  style: GoogleFonts.outfit(
                                    color: isBooked 
                                        ? Colors.grey[500] 
                                        : (isSelected ? Colors.white : const Color(0xFF2C3E50)),
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                                if (isBooked)
                                  const Text(
                                    'Not Available',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
            const SizedBox(height: 32),

            Text(
              'Additional Notes (Optional)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe your symptoms or any specific concerns...',
                hintStyle: const TextStyle(color: Color(0xFFBDC3C7)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 40),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isBooking ? null : _bookAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B9AE1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: _isBooking 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Confirm Appointment',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Note: This is an offline consultation at the clinic.',
                style: TextStyle(fontSize: 12, color: Color(0xFF95A5A6), fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
