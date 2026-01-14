import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:geolocator/geolocator.dart';
import 'package:skin_disease1/doctor_dashboard.dart';


class DoctorProfileSetupScreen extends StatefulWidget {
  @override
  _DoctorProfileSetupScreenState createState() => _DoctorProfileSetupScreenState();
}

class _DoctorProfileSetupScreenState extends State<DoctorProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _qualificationController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _specializationController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _bookingNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  double? _lat;
  double? _lng;
  bool _gettingLocation = false;

  File? _imageFile;
  String? _imageUrl;
  bool _isUploading = false;
  bool _isLoading = false;


  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _gettingLocation = true);
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location captured!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
    } finally {
      setState(() => _gettingLocation = false);
    }
  }

  final cloudinary = CloudinaryPublic('dgn6dvfzm', 'skindisease_images', cache: false);



  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
        _isUploading = true;
      });

      try {
        final response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(image.path, resourceType: CloudinaryResourceType.Image),
        );
        setState(() {
          _imageUrl = response.secureUrl;
          _isUploading = false;
        });
      } catch (e) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please upload a profile photo')));
      return;
    }


    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doctorData = {
        'uid': user.uid,
        'name': _nameController.text.trim(),
        'designation': _designationController.text.trim(),
        'qualification': _qualificationController.text.trim(),
        'years_of_experience': int.tryParse(_experienceController.text.trim()) ?? 0,
        'specialization': _specializationController.text.trim(),
        'place': _placeController.text.trim(),
        'booking_number': _bookingNumberController.text.trim(),
        'address': _addressController.text.trim(),
        'profile_image': _imageUrl,
        'latitude': _lat,
        'longitude': _lng,
        'is_working': true,
        'approval_status': 'approved',
        'created_at': FieldValue.serverTimestamp(),
      };

      // Add to doctors collection
      await FirebaseFirestore.instance.collection('doctors').doc(user.uid).set(doctorData);
      
      // Update user document
      await FirebaseFirestore.instance.collection('user').doc(user.uid).update({
        'isProfileComplete': true,
        'profile_image': _imageUrl,
        'name': _nameController.text.trim(),
      });
      
      // Update Firebase Auth name
      await user.updateDisplayName(_nameController.text.trim());

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DoctorDashboard()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Complete Your Profile', style: TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
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
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(60), child: Image.file(_imageFile!, fit: BoxFit.cover))
                      : _imageUrl != null
                          ? ClipRRect(borderRadius: BorderRadius.circular(60), child: Image.network(_imageUrl!, fit: BoxFit.cover))
                          : Icon(Icons.add_a_photo, size: 40, color: Color(0xFF3B9AE1)),
                ),
              ),
              SizedBox(height: 8),
              Text(_isUploading ? 'Uploading...' : 'Profile Photo', style: TextStyle(color: Color(0xFF7F8C8D))),
              SizedBox(height: 32),
              
              _buildField(_nameController, 'Full Name', Icons.person),
              SizedBox(height: 16),
              _buildField(_designationController, 'Designation (e.g. Dermatologist)', Icons.work),
              SizedBox(height: 16),
              _buildField(_qualificationController, 'Qualification (e.g. MBBS, MD)', Icons.school),
              SizedBox(height: 16),
              _buildField(_specializationController, 'Specialization', Icons.medical_services),
              SizedBox(height: 16),
              _buildField(_experienceController, 'Years of Experience', Icons.timeline, keyboard: TextInputType.number),
              SizedBox(height: 16),
              _buildField(_placeController, 'City / Place', Icons.location_city),
              SizedBox(height: 16),
              
              // Location Button
              Container(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _gettingLocation ? null : _getCurrentLocation,
                  icon: _gettingLocation ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(Icons.my_location),
                  label: Text(_lat != null ? 'Location Captured' : 'Capture Clinic Location'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _lat != null ? Colors.green : Color(0xFF3B9AE1),
                    side: BorderSide(color: _lat != null ? Colors.green : Color(0xFF3B9AE1)),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              if (_lat != null) Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Lat: ${_lat!.toStringAsFixed(4)}, Lng: ${_lng!.toStringAsFixed(4)}', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
              
              SizedBox(height: 16),
              _buildField(_bookingNumberController, 'Booking Contact Number', Icons.phone, keyboard: TextInputType.phone),
              SizedBox(height: 16),
              _buildField(_addressController, 'Clinic Address', Icons.location_on, maxLines: 3),
              
              

              SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading || _isUploading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3B9AE1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  child: _isLoading 
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Continue to Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
        prefixIcon: Icon(icon, color: Color(0xFF3B9AE1)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
