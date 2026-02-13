import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:skin_disease1/afterlogin.dart';
import 'package:skin_disease1/admin_dashboard.dart';
import 'package:skin_disease1/doctor_dashboard.dart';
import 'package:skin_disease1/doctor_profile_setup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skin_disease1/main.dart';

Future<void> reg({
  required String email,
  required String password1,
  required String name,
  required String role,
  String? idProofUrl,
  required BuildContext context,
}) async {
  final trimmedEmail = email.trim();
  final trimmedPassword = password1.trim();
  try {
    UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
          email: trimmedEmail,
          password: password1, // Removed trim for passwords
        );
    User? user = userCredential.user;

    if (user != null && user.uid.isNotEmpty) {
      // Update display name in Firebase Auth
      await user.updateDisplayName(name);

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

      await FirebaseFirestore.instance
          .collection('user')
          .doc(user.uid)
          .set(userData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            role == 'doctor'
                ? "Doctor account created. Please wait for admin approval."
                : "User created successfully",
          ),
        ),
      );

      Navigator.pop(context); // Go back to login
    }
  } on FirebaseAuthException catch (e) {
    debugPrint('Registration Error: ${e.code} - ${e.message}');
    String errorMessage = "Registration failed";
    if (e.code == 'email-already-in-use') {
      errorMessage = "This email is already registered";
    } else if (e.code == 'weak-password') {
      errorMessage = "The password is too weak";
    } else if (e.code == 'invalid-email') {
      errorMessage = "Invalid email format";
    } else {
      errorMessage = e.message ?? "Registration error";
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(errorMessage)));
  } catch (e) {
    debugPrint('Registration failed: $e');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.toString())));
  }
}

Future<void> login({
  required String email,
  required String password1,
  required BuildContext context,
}) async {
  final trimmedEmail = email.trim();
  final trimmedPassword = password1.trim();
  const String adminEmail = "admin@dermasense.com";
  const String adminPassword = "admin123";

  if (trimmedEmail == adminEmail && password1.trim() == adminPassword) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAdminLoggedIn', true);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Admin login successful")));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AdminDashboard()),
    );
    return;
  }

  try {
    UserCredential userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(
          email: trimmedEmail,
          password: password1, // Removed trim for passwords
        );

    User? user = userCredential.user;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception("User data not found");
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String role = userData['role'] ?? 'patient';

      if (role == 'doctor') {
        String status = userData['status'] ?? 'pending';
        if (status == 'pending') {
          await FirebaseAuth.instance.signOut();
          throw Exception(
            "Your account is pending approval. Please wait for admin review.",
          );
        } else if (status == 'rejected') {
          await FirebaseAuth.instance.signOut();
          throw Exception("Your application has been rejected by admin.");
        }

        bool isProfileComplete = userData['isProfileComplete'] ?? false;
        if (!isProfileComplete) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DoctorProfileSetupScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DoctorDashboard()),
          );
        }
      } else {
        // Patient
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ImagePickerPage()),
        );
      }
    }
  } on FirebaseAuthException catch (e) {
    debugPrint('Auth Error: ${e.code} - ${e.message}');
    String errorMessage = "Login failed";
    if (e.code == 'invalid-credential') {
      errorMessage = "Incorrect email or password";
    } else if (e.code == 'user-not-found') {
      errorMessage = "No user found with this email";
    } else if (e.code == 'wrong-password') {
      errorMessage = "Incorrect password";
    } else if (e.code == 'invalid-email') {
      errorMessage = "Invalid email format";
    } else {
      errorMessage = e.message ?? "Authentication error";
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(errorMessage)));
  } catch (e) {
    debugPrint('Login failed: $e');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.toString())));
  }
}

Future<void> forgotpassword({
  required String email,
  required BuildContext context,
}) async {
  final trimmedEmail = email.trim();
  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: trimmedEmail);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Password reset email sent. Please check your inbox and spam folder.",
        ),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.toString())));
  }
}

Future<void> logoutUser(BuildContext context) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isAdminLoggedIn');
    await FirebaseAuth.instance.signOut();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AuthWrapper()),
      (route) => false,
    );
  } catch (e) {
    debugPrint('Logout failed: $e');
  }
}
