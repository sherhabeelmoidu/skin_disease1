import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:skin_disease1/afterlogin.dart';
import 'package:skin_disease1/admin_dashboard.dart';

Future<void> reg({
  required String email,
  required String password1,
  required String name,
  required BuildContext context,
}) async {
  try {
    UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password1);
    User? user = userCredential.user;
    // Use uid when available; fallback to auto-id document (shouldn't normally be needed)
    if (user != null && user.uid.isNotEmpty) {
      await FirebaseFirestore.instance.collection('user').doc(user.uid).set({
        "email": email,
        "name": name,
        "created_at": FieldValue.serverTimestamp(),
      });
     
    } else {
      final ref = await FirebaseFirestore.instance.collection('user').add({
        "email": email,
        "name": name,
        "note": 'uid_missing',
        "created_at": FieldValue.serverTimestamp(),
      });
      debugPrint('User document created with auto-id ${ref.id}');
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("User created successfully")));
  } catch (e) {
    debugPrint('Registration failed: $e');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.toString())));
  }
}

/// Debug helper: list all documents in `user` collection (returns list and prints each)
Future<List<Map<String, dynamic>>> fetchUsers() async {
  final snapshot = await FirebaseFirestore.instance.collection('user').get();
  final List<Map<String, dynamic>> users = [];
  for (final doc in snapshot.docs) {
    final data = doc.data();
    data['id'] = doc.id;
    users.add(data);
    debugPrint('fetchUsers: id=${doc.id} data=$data');
  }
  return users;
}

Future<void> login({
  required String email,
  required String password1,
  required BuildContext context,
}) async {
  // Check for admin credentials first
  const String adminEmail = "admin@dermasense.com";
  const String adminPassword = "admin123";

  if (email == adminEmail && password1 == adminPassword) {
    // Admin login
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Admin login successful")),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AdminDashboard()),
    );
    return;
  }

  // Regular user login
  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password1,
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Login successful")));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ImagePickerPage()),
    );
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.toString())));
  }
}

Future<void> forgotpassword({required String email,

  required BuildContext context,
})async {
  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Password reset email sent.")));
   
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.toString())));
  }
}
