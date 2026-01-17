import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:google_fonts/google_fonts.dart';

class DoctorProfessionalDetailsScreen extends StatefulWidget {
  const DoctorProfessionalDetailsScreen({Key? key}) : super(key: key);

  @override
  State<DoctorProfessionalDetailsScreen> createState() => _DoctorProfessionalDetailsScreenState();
}

class _DoctorProfessionalDetailsScreenState extends State<DoctorProfessionalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _qualificationController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _bookingNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  File? _imageFile;
  Uint8List? _webImageBytes;
  String? _imageUrl;
  bool _isUploading = false;
  bool _isLoading = true;
  bool _isSaving = false;

  final cloudinary = CloudinaryPublic('dgn6dvfzm', 'skindisease_images', cache: false);

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
  }

  Future<void> _loadDoctorData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance.collection('doctors').doc(user.uid).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _designationController.text = data['designation'] ?? '';
          _qualificationController.text = data['qualification'] ?? '';
          _experienceController.text = data['years_of_experience']?.toString() ?? '';
          _specializationController.text = data['specialization'] ?? '';
          _placeController.text = data['place'] ?? '';
          _bookingNumberController.text = data['booking_number'] ?? '';
          _addressController.text = data['address'] ?? '';
          _imageUrl = data['profile_image'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _isUploading = true;
      });

      try {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _webImageBytes = bytes;
          });
          final response = await cloudinary.uploadFile(
            CloudinaryFile.fromBytesData(
              bytes,
              identifier: 'doc_${DateTime.now().millisecondsSinceEpoch}',
              resourceType: CloudinaryResourceType.Image,
              folder: 'profiles',
            ),
          );
          _imageUrl = response.secureUrl;
        } else {
          setState(() {
            _imageFile = File(image.path);
          });
          final response = await cloudinary.uploadFile(
            CloudinaryFile.fromFile(
              image.path, 
              resourceType: CloudinaryResourceType.Image,
              folder: 'profiles',
            ),
          );
          _imageUrl = response.secureUrl;
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doctorData = {
        'name': _nameController.text.trim(),
        'designation': _designationController.text.trim(),
        'qualification': _qualificationController.text.trim(),
        'years_of_experience': int.tryParse(_experienceController.text.trim()) ?? 0,
        'specialization': _specializationController.text.trim(),
        'place': _placeController.text.trim(),
        'booking_number': _bookingNumberController.text.trim(),
        'address': _addressController.text.trim(),
        'profile_image': _imageUrl,
        'updated_at': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('doctors').doc(user.uid).update(doctorData);
      
      await FirebaseFirestore.instance.collection('user').doc(user.uid).update({
        'profile_image': _imageUrl,
        'name': _nameController.text.trim(),
      });
      
      await user.updateDisplayName(_nameController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
      );
      
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Professional Details',
          style: GoogleFonts.outfit(color: const Color(0xFF2C3E50), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 10)],
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: (_imageFile != null || _webImageBytes != null)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(60), 
                                child: kIsWeb 
                                  ? Image.memory(_webImageBytes!, fit: BoxFit.cover)
                                  : Image.file(_imageFile!, fit: BoxFit.cover))
                            : _imageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(60),
                                    child: Image.network(_imageUrl!, fit: BoxFit.cover),
                                  )
                                : const Icon(Icons.add_a_photo, size: 40, color: Color(0xFF3B9AE1)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isUploading ? 'Uploading...' : 'Tap to change photo',
                      style: const TextStyle(color: Color(0xFF7F8C8D)),
                    ),
                    const SizedBox(height: 32),
                    
                    _buildField(_nameController, 'Full Name', Icons.person),
                    const SizedBox(height: 16),
                    _buildField(_designationController, 'Designation (e.g. Dermatologist)', Icons.work),
                    const SizedBox(height: 16),
                    _buildField(_qualificationController, 'Qualification (e.g. MBBS, MD)', Icons.school),
                    const SizedBox(height: 16),
                    _buildField(_specializationController, 'Specialization', Icons.medical_services),
                    const SizedBox(height: 16),
                    _buildField(_experienceController, 'Years of Experience', Icons.timeline, keyboard: TextInputType.number),
                    const SizedBox(height: 16),
                    _buildField(_placeController, 'City / Place', Icons.location_city),
                    const SizedBox(height: 16),
                    _buildField(_bookingNumberController, 'Booking Contact Number', Icons.phone, keyboard: TextInputType.phone),
                    const SizedBox(height: 16),
                    _buildField(_addressController, 'Clinic Address', Icons.location_on, maxLines: 3),
                    
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving || _isUploading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B9AE1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        ),
                        child: _isSaving 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Save Changes',
                              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {TextInputType keyboard = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      validator: (v) => v!.isEmpty ? 'Field required' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF3B9AE1)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
