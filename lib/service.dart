import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:skin_disease1/afterlogin.dart';
import 'package:skin_disease1/admin_dashboard.dart';
import 'package:skin_disease1/doctor_dashboard.dart';
import 'package:skin_disease1/doctor_profile_setup.dart';

Future<void> reg({
  required String email,
  required String password1,
  required String name,
  required String role,
  String? idProofUrl,
  required BuildContext context,
}) async {
  try {
    UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password1);
    User? user = userCredential.user;
    
    if (user != null && user.uid.isNotEmpty) {
      Map<String, dynamic> userData = {
        "email": email,
        "name": name,
        "role": role,
        "created_at": FieldValue.serverTimestamp(),
      };

      if (role == 'doctor') {
        userData['status'] = 'pending';
        userData['idProofUrl'] = idProofUrl;
        userData['isProfileComplete'] = false;
      }

      await FirebaseFirestore.instance.collection('user').doc(user.uid).set(userData);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(role == 'doctor' ? "Doctor account created. Please wait for admin approval." : "User created successfully"))
      );
      
      Navigator.pop(context); // Go back to login
    }
  } catch (e) {
    debugPrint('Registration failed: $e');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
  }
}

Future<void> login({
  required String email,
  required String password1,
  required BuildContext context,
}) async {
  const String adminEmail = "admin@dermasense.com";
  const String adminPassword = "admin123";

  if (email == adminEmail && password1 == adminPassword) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Admin login successful")));
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AdminDashboard()));
    return;
  }

  try {
    UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password1,
    );
    
    User? user = userCredential.user;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('user').doc(user.uid).get();
      
      if (!userDoc.exists) {
        throw Exception("User data not found");
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String role = userData['role'] ?? 'patient';

      if (role == 'doctor') {
        String status = userData['status'] ?? 'pending';
        if (status == 'pending') {
          await FirebaseAuth.instance.signOut();
          throw Exception("Your account is pending approval. Please wait for admin review.");
        } else if (status == 'rejected') {
          await FirebaseAuth.instance.signOut();
          throw Exception("Your application has been rejected by admin.");
        }

        bool isProfileComplete = userData['isProfileComplete'] ?? false;
        if (!isProfileComplete) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DoctorProfileSetupScreen()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DoctorDashboard()));
        }
      } else {
        // Patient
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ImagePickerPage()));
      }
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
  }
}

Future<void> forgotpassword({required String email, required BuildContext context}) async {
  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password reset email sent.")));
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
  }
}
