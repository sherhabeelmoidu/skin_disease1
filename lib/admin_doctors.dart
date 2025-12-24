import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class AdminDoctors extends StatefulWidget {
  @override
  State<AdminDoctors> createState() => _AdminDoctorsState();
}

class _AdminDoctorsState extends State<AdminDoctors> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cloudinary configuration - Replace with your actual credentials
  // Get these from https://cloudinary.com/console
  // 1. Go to your Cloudinary dashboard
  // 2. Copy your Cloud Name from the dashboard
  // 3. Create an upload preset in Settings > Upload
  final cloudinary = CloudinaryPublic('your-cloud-name', 'your-upload-preset', cache: false);

  // Controllers for add/edit form
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _qualificationController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _bookingNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isWorking = true;
  File? _selectedImage;
  String? _doctorImageUrl;
  String? _editingDoctorId;

  @override
  void dispose() {
    _nameController.dispose();
    _designationController.dispose();
    _qualificationController.dispose();
    _experienceController.dispose();
    _specializationController.dispose();
    _placeController.dispose();
    _bookingNumberController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });

      try {
        // Upload to Cloudinary
        final response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(image.path, resourceType: CloudinaryResourceType.Image),
        );

        setState(() {
          _doctorImageUrl = response.secureUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Doctor image uploaded successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _designationController.clear();
    _qualificationController.clear();
    _experienceController.clear();
    _specializationController.clear();
    _placeController.clear();
    _bookingNumberController.clear();
    _addressController.clear();
    setState(() {
      _selectedImage = null;
      _doctorImageUrl = null;
      _isWorking = true;
      _editingDoctorId = null;
    });
  }

  Future<void> _saveDoctor() async {
    if (_nameController.text.trim().isEmpty ||
        _designationController.text.trim().isEmpty ||
        _qualificationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    try {
      final doctorData = {
        'name': _nameController.text.trim(),
        'designation': _designationController.text.trim(),
        'qualification': _qualificationController.text.trim(),
        'years_of_experience': int.tryParse(_experienceController.text.trim()) ?? 0,
        'specialization': _specializationController.text.trim(),
        'place': _placeController.text.trim(),
        'booking_number': _bookingNumberController.text.trim(),
        'is_working': _isWorking,
        'address': _isWorking ? _addressController.text.trim() : '',
        'profile_image': _doctorImageUrl,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (_editingDoctorId != null) {
        // Update existing doctor
        await _firestore.collection('doctors').doc(_editingDoctorId).update({
          ...doctorData,
          'updated_at': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Doctor updated successfully')),
        );
      } else {
        // Add new doctor
        await _firestore.collection('doctors').add(doctorData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Doctor added successfully')),
        );
      }

      _clearForm();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save doctor: $e')),
      );
    }
  }

  void _showDoctorForm([String? doctorId]) {
    if (doctorId != null) {
      // Load existing doctor data for editing
      _firestore.collection('doctors').doc(doctorId).get().then((doc) {
        if (doc.exists) {
          final data = doc.data()!;
          _nameController.text = data['name'] ?? '';
          _designationController.text = data['designation'] ?? '';
          _qualificationController.text = data['qualification'] ?? '';
          _experienceController.text = data['years_of_experience']?.toString() ?? '';
          _specializationController.text = data['specialization'] ?? '';
          _placeController.text = data['place'] ?? '';
          _bookingNumberController.text = data['booking_number'] ?? '';
          _addressController.text = data['address'] ?? '';
          setState(() {
            _isWorking = data['is_working'] ?? true;
            _doctorImageUrl = data['profile_image'];
            _editingDoctorId = doctorId;
          });
        }
      });
    } else {
      _clearForm();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.9,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _editingDoctorId != null ? 'Edit Doctor' : 'Add New Doctor',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                SizedBox(height: 20),

                // Image picker
                Center(
                  child: GestureDetector(
                    onTap: () => _pickImage(),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: Color(0xFFE0E0E0)),
                      ),
                      child: _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : _doctorImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: Image.network(
                                    _doctorImageUrl!,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.add_a_photo,
                                        color: Color(0xFF7F8C8D),
                                        size: 40,
                                      );
                                    },
                                  ),
                                )
                              : Icon(
                                  Icons.add_a_photo,
                                  color: Color(0xFF7F8C8D),
                                  size: 40,
                                ),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Form fields
                _buildTextField(_nameController, 'Full Name *', Icons.person),
                SizedBox(height: 16),
                _buildTextField(_designationController, 'Designation *', Icons.work),
                SizedBox(height: 16),
                _buildTextField(_qualificationController, 'Qualification *', Icons.school),
                SizedBox(height: 16),
                _buildTextField(_experienceController, 'Years of Experience', Icons.timeline, keyboardType: TextInputType.number),
                SizedBox(height: 16),
                _buildTextField(_specializationController, 'Specialization', Icons.medical_services),
                SizedBox(height: 16),
                _buildTextField(_placeController, 'Place/City', Icons.location_city),
                SizedBox(height: 16),
                _buildTextField(_bookingNumberController, 'Booking Number', Icons.phone),

                SizedBox(height: 16),
                // Working status
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFFE0E0E0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Currently Working',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Radio<bool>(
                            value: true,
                            groupValue: _isWorking,
                            onChanged: (value) {
                              setState(() {
                                _isWorking = value!;
                              });
                            },
                            activeColor: Color(0xFF3B9AE1),
                          ),
                          Text('Yes'),
                          SizedBox(width: 20),
                          Radio<bool>(
                            value: false,
                            groupValue: _isWorking,
                            onChanged: (value) {
                              setState(() {
                                _isWorking = value!;
                              });
                            },
                            activeColor: Color(0xFF3B9AE1),
                          ),
                          Text('No'),
                        ],
                      ),
                    ],
                  ),
                ),

                if (_isWorking) ...[
                  SizedBox(height: 16),
                  _buildTextField(_addressController, 'Work Address/Clinic Address', Icons.location_on),
                ],

                SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Color(0xFF7F8C8D)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text('Cancel'),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveDoctor,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF3B9AE1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(_editingDoctorId != null ? 'Update' : 'Add Doctor'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Color(0xFF7F8C8D)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF3B9AE1)),
        ),
        filled: true,
        fillColor: Color(0xFFF8F9FA),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      style: TextStyle(color: Color(0xFF2C3E50)),
    );
  }

  void _deleteDoctor(String doctorId, String doctorName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Doctor'),
        content: Text('Are you sure you want to delete Dr. $doctorName? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firestore.collection('doctors').doc(doctorId).delete();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Doctor deleted successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete doctor: $e')),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header with add button
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Doctors Management',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      SizedBox(height: 4),
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestore.collection('doctors').snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(
                              '${snapshot.data!.docs.length} doctors',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF7F8C8D),
                              ),
                            );
                          }
                          return Text(
                            'Loading...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF7F8C8D),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                FloatingActionButton(
                  onPressed: () => _showDoctorForm(),
                  backgroundColor: Color(0xFF3B9AE1),
                  foregroundColor: Colors.white,
                  mini: true,
                  child: Icon(Icons.add),
                ),
              ],
            ),
          ),

          // Doctors list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('doctors').orderBy('created_at', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.medical_services_outlined,
                          size: 64,
                          color: Color(0xFFBDC3C7),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No doctors added yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF7F8C8D),
                          ),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _showDoctorForm(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF3B9AE1),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text('Add First Doctor'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doctorDoc = snapshot.data!.docs[index];
                    final doctorData = doctorDoc.data() as Map<String, dynamic>;

                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Doctor avatar
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Color(0xFF3B9AE1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    (doctorData['name'] ?? 'D')[0].toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),

                              // Doctor info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dr. ${doctorData['name'] ?? 'Unknown'}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      doctorData['designation'] ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF7F8C8D),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      doctorData['specialization'] ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF3B9AE1),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Action menu
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showDoctorForm(doctorDoc.id);
                                  } else if (value == 'delete') {
                                    _deleteDoctor(doctorDoc.id, doctorData['name'] ?? 'Unknown');
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, color: Color(0xFF3B9AE1)),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          SizedBox(height: 12),

                          // Additional details
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.school, size: 16, color: Color(0xFF7F8C8D)),
                                    SizedBox(width: 8),
                                    Text(
                                      doctorData['qualification'] ?? 'N/A',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.timeline, size: 16, color: Color(0xFF7F8C8D)),
                                    SizedBox(width: 8),
                                    Text(
                                      '${doctorData['years_of_experience'] ?? 0} years experience',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.location_city, size: 16, color: Color(0xFF7F8C8D)),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        doctorData['place'] ?? 'N/A',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF2C3E50),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (doctorData['is_working'] == true && doctorData['address']?.isNotEmpty == true) ...[
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: 16, color: Color(0xFF7F8C8D)),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          doctorData['address'],
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF2C3E50),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.phone, size: 16, color: Color(0xFF7F8C8D)),
                                    SizedBox(width: 8),
                                    Text(
                                      doctorData['booking_number'] ?? 'N/A',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
    );
  }
}
