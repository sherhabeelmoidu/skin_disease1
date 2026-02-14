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
  bool _isLoading = false;

  final List<String> _commonSlots = [
    "09:00 AM",
    "09:30 AM",
    "10:00 AM",
    "10:30 AM",
    "11:00 AM",
    "11:30 AM",
    "12:00 PM",
    "12:30 PM",
    "02:00 PM",
    "02:30 PM",
    "03:00 PM",
    "03:30 PM",
    "04:00 PM",
    "04:30 PM",
    "05:00 PM",
    "05:30 PM",
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
      final existing = await _firestore
          .collection('doctors')
          .doc(_uid)
          .collection('slots')
          .where('date', isEqualTo: dateStr)
          .where('time', isEqualTo: time)
          .get();

      if (existing.docs.isEmpty) {
        await _firestore
            .collection('doctors')
            .doc(_uid)
            .collection('slots')
            .add({
              'date': dateStr,
              'time': time,
              'isBooked': false,
              'bookedBy': null,
              'createdAt': FieldValue.serverTimestamp(),
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Slot $time added'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _generateDefaultSlots() async {
    if (_uid == null) return;
    String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    setState(() => _isLoading = true);

    try {
      final batch = _firestore.batch();
      final slotsCollection = _firestore
          .collection('doctors')
          .doc(_uid)
          .collection('slots');

      final existing = await slotsCollection
          .where('date', isEqualTo: dateStr)
          .get();
      final existingTimes = existing.docs
          .map((d) => (d.data() as dynamic)['time'])
          .toSet();

      int addedCount = 0;
      for (String time in _commonSlots) {
        if (!existingTimes.contains(time)) {
          final newDocRef = slotsCollection.doc();
          batch.set(newDocRef, {
            'date': dateStr,
            'time': time,
            'isBooked': false,
            'bookedBy': null,
            'createdAt': FieldValue.serverTimestamp(),
          });
          addedCount++;
        }
      }

      if (addedCount > 0) {
        await batch.commit();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added $addedCount default slots'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error generating slots: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _deleteAllSlots() async {
    if (_uid == null) return;
    String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Available Slots?'),
        content: Text(
          'This will remove all available (unbooked) slots for $dateStr.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final slots = await _firestore
          .collection('doctors')
          .doc(_uid)
          .collection('slots')
          .where('date', isEqualTo: dateStr)
          .where('isBooked', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in slots.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting slots: $e');
    } finally {
      setState(() => _isLoading = false);
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
        title: Text(
          'Manage Slots',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, MMM d').format(_selectedDate),
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Manage your availability',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _selectDate(context),
                      icon: const Icon(Icons.calendar_month, size: 18),
                      label: const Text('Change Date'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _generateDefaultSlots,
                        icon: const Icon(Icons.auto_awesome, size: 16),
                        label: const Text('Bulk Add Defaults'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF3B9AE1),
                          side: const BorderSide(color: Color(0xFF3B9AE1)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _deleteAllSlots,
                        icon: const Icon(Icons.delete_sweep, size: 16),
                        label: const Text('Clear All'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red[400],
                          side: BorderSide(color: Colors.red[200]!),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: Row(
              children: [
                Container(
                  width: 130,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      right: BorderSide(color: Colors.grey.withOpacity(0.1)),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Click to Add',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _commonSlots.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(
                                _commonSlots[index],
                                style: const TextStyle(fontSize: 12),
                              ),
                              onTap: () => _addSlot(_commonSlots[index]),
                              dense: true,
                              trailing: const Icon(
                                Icons.add,
                                size: 14,
                                color: Color(0xFF3B9AE1),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

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

                      final docs = snapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.more_time,
                                size: 48,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No slots for this date',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }

                      DateTime _parseTime(String timeStr) {
                        try {
                          return DateFormat('hh:mm a').parse(timeStr);
                        } catch (e) {
                          return DateTime(2000);
                        }
                      }

                      final sortedSlots = List<QueryDocumentSnapshot>.from(
                        docs,
                      );
                      sortedSlots.sort((a, b) {
                        final aTime =
                            (a.data() as Map<String, dynamic>)['time'] ?? '';
                        final bTime =
                            (b.data() as Map<String, dynamic>)['time'] ?? '';
                        return _parseTime(aTime).compareTo(_parseTime(bTime));
                      });

                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 1.8,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: sortedSlots.length,
                        itemBuilder: (context, index) {
                          final slotData =
                              sortedSlots[index].data() as Map<String, dynamic>;
                          final slotId = sortedSlots[index].id;
                          final bool isBooked = slotData['isBooked'] ?? false;

                          return Container(
                            decoration: BoxDecoration(
                              color: isBooked ? Colors.red[50] : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: isBooked
                                    ? Colors.red[100]!
                                    : Colors.grey[100]!,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        slotData['time'],
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: isBooked
                                              ? Colors.red[700]
                                              : const Color(0xFF2C3E50),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isBooked
                                                  ? Colors.red
                                                  : Colors.green,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            isBooked ? 'Booked' : 'Available',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: isBooked
                                                  ? Colors.red[400]
                                                  : Colors.green[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isBooked)
                                  Positioned(
                                    right: 4,
                                    top: 4,
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.remove_circle_outline,
                                        size: 18,
                                        color: Colors.grey[400],
                                      ),
                                      onPressed: () => _removeSlot(slotId),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
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
