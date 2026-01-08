import 'package:flutter/material.dart';
import 'package:skin_disease1/login.dart';
import 'package:skin_disease1/service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';

class SignUp extends StatefulWidget {
  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  TextEditingController namecontroller = TextEditingController();
  TextEditingController emailcontroller = TextEditingController();
  TextEditingController password1controller = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = 'patient';
  File? _idProofImage;
  String? _idProofUrl;
  bool _isUploading = false;

  final cloudinary = CloudinaryPublic('dgn6dvfzm', 'skindisease_images', cache: false);

  Future<void> _pickIdProof() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _idProofImage = File(image.path);
        _isUploading = true;
      });

      try {
        final response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(image.path, resourceType: CloudinaryResourceType.Image),
        );
        setState(() {
          _idProofUrl = response.secureUrl;
          _isUploading = false;
        });
      } catch (e) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Sign Up',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Image.asset(
                  'assets/icon/logo.png',
                  height: 80,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
                Text(
                  'Create your account',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                ),
                SizedBox(height: 8),
                Text(
                  'to get started',
                  style: TextStyle(fontSize: 16, color: Color(0xFF7F8C8D)),
                ),
                SizedBox(height: 30),

                // Role Selection
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedRole = 'patient'),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'patient' ? Color(0xFF3B9AE1) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Patient',
                                style: TextStyle(
                                  color: _selectedRole == 'patient' ? Colors.white : Color(0xFF7F8C8D),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedRole = 'doctor'),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedRole == 'doctor' ? Color(0xFF3B9AE1) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Doctor',
                                style: TextStyle(
                                  color: _selectedRole == 'doctor' ? Colors.white : Color(0xFF7F8C8D),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                _buildTextField(namecontroller, 'Full Name', Icons.person_outline),
                SizedBox(height: 16),
                _buildTextField(emailcontroller, 'Email', Icons.email_outlined),
                SizedBox(height: 16),
                _buildTextField(password1controller, 'Password', Icons.lock_outline, obscure: _obscurePassword, 
                  suffix: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Color(0xFF7F8C8D)),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  )),
                SizedBox(height: 16),
                _buildTextField(confirmPasswordController, 'Confirm Password', Icons.lock_outline, obscure: _obscureConfirmPassword,
                  suffix: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Color(0xFF7F8C8D)),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  )),
                
                if (_selectedRole == 'doctor') ...[
                  SizedBox(height: 24),
                  Text(
                    'Upload ID Proof / Medical License',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                  ),
                  SizedBox(height: 12),
                  GestureDetector(
                    onTap: _isUploading ? null : _pickIdProof,
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFFE0E0E0), style: BorderStyle.solid),
                      ),
                      child: _idProofImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(_idProofImage!, fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cloud_upload_outlined, size: 40, color: Color(0xFF3B9AE1)),
                                SizedBox(height: 8),
                                Text(_isUploading ? 'Uploading...' : 'Choose File', style: TextStyle(color: Color(0xFF7F8C8D))),
                              ],
                            ),
                    ),
                  ),
                ],

                SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : () {
                      if (_selectedRole == 'doctor' && _idProofUrl == null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please upload ID proof')));
                        return;
                      }
                      if (password1controller.text != confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Passwords do not match')));
                        return;
                      }
                      reg(
                        email: emailcontroller.text,
                        password1: password1controller.text,
                        name: namecontroller.text,
                        role: _selectedRole,
                        idProofUrl: _idProofUrl,
                        context: context,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3B9AE1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                    child: Text('Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account? ", style: TextStyle(color: Color(0xFF7F8C8D))),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoginApp())),
                      child: Text("Log In", style: TextStyle(color: Color(0xFF3B9AE1), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool obscure = false, Widget? suffix}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Color(0xFF7F8C8D)),
          suffixIcon: suffix,
          hintText: hint,
          hintStyle: TextStyle(color: Color(0xFFBDC3C7)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
        style: TextStyle(color: Color(0xFF2C3E50)),
      ),
    );
  }
}
