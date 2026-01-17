import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class DoctorSlotsScreen extends StatefulWidget {
  const DoctorSlotsScreen({Key? key}) : super(key: key);

  @override
  State<DoctorSlotsScreen> createState() => _DoctorSlotsScreenState();
}

class _DoctorSlotsScreenState extends State<DoctorSlotsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  DateTime _selectedDate = DateTime.now();
  final List<String> _commonSlots = [
    "09:00 AM", "09:30 AM", "10:00 AM", "10:30 AM",
    "11:00 AM", "11:30 AM", "12:00 PM", "12:30 PM",
    "02:00 PM", "02:30 PM", "03:00 PM", "03:30 PM",
    "04:00 PM", "04:30 PM", "05:00 PM", "05:30 PM"
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _addSlot(String time) async {
    if (_uid == null) return;
    String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    
    try {
      // Check if slot already exists
      final existing = await _firestore
          .collection('doctors')
          .doc(_uid)
          .collection('slots')
          .where('date', isEqualTo: dateStr)
          .where('time', isEqualTo: time)
          .get();

      if (existing.docs.isEmpty) {
        await _firestore.collection('doctors').doc(_uid).collection('slots').add({
          'date': dateStr,
          'time': time,
          'isBooked': false,
          'bookedBy': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Slot $time added successfully'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Slot $time already exists'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding slot: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeSlot(String slotId) async {
    if (_uid == null) return;
    await _firestore
        .collection('doctors')
        .doc(_uid)
        .collection('slots')
        .doc(slotId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Manage Slots', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Date Selection Header
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, MMM d').format(_selectedDate),
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Text('Select a date to manage slots', style: TextStyle(color: Colors.grey)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _selectDate(context),
                  icon: const Icon(Icons.calendar_month, size: 18),
                  label: const Text('Change'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Row(
              children: [
                // Quick Add Panel
                Container(
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(right: BorderSide(color: Colors.grey.withOpacity(0.1))),
                  ),
                  child: ListView.builder(
                    itemCount: _commonSlots.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_commonSlots[index], style: const TextStyle(fontSize: 12)),
                        onTap: () => _addSlot(_commonSlots[index]),
                        dense: true,
                        trailing: const Icon(Icons.add, size: 14, color: Color(0xFF3B9AE1)),
                      );
                    },
                  ),
                ),

                // Active Slots Panel
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('doctors')
                        .doc(_uid)
                        .collection('slots')
                        .where('date', isEqualTo: dateStr)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const SizedBox(height: 12),
                              Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                            ],
                          ),
                        );
                      }
                      
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final slots = snapshot.data!.docs;
                      
                      // Sort slots by time in memory
                      slots.sort((a, b) {
                        final aData = a.data() as Map<String, dynamic>;
                        final bData = b.data() as Map<String, dynamic>;
                        final aTime = aData['time'] ?? '';
                        final bTime = bData['time'] ?? '';
                        return aTime.compareTo(bTime);
                      });
                      
                      if (slots.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.more_time, size: 48, color: Colors.grey[300]),
                              const SizedBox(height: 12),
                              const Text('No slots added for this date', style: TextStyle(color: Colors.grey)),
                              const SizedBox(height: 8),
                              const Text('Tap a time on the left to add', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        );
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2.5,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: slots.length,
                        itemBuilder: (context, index) {
                          final slotData = slots[index].data() as Map<String, dynamic>;
                          final slotId = slots[index].id;
                          final bool isBooked = slotData['isBooked'] ?? false;

                          return Container(
                            decoration: BoxDecoration(
                              color: isBooked ? Colors.red[50] : Colors.green[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isBooked ? Colors.red[100]! : Colors.green[100]!),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        slotData['time'],
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          color: isBooked ? Colors.red[700] : Colors.green[700],
                                        ),
                                      ),
                                      Text(
                                        isBooked ? 'Booked' : 'Available',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isBooked ? Colors.red[400] : Colors.green[400],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isBooked)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, size: 14, color: Colors.grey),
                                      onPressed: () => _removeSlot(slotId),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
