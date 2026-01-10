import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:skin_disease1/firebase_options.dart';
import 'package:skin_disease1/firstopen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skin_disease1/afterlogin.dart';
import 'package:skin_disease1/admin_dashboard.dart';
import 'package:skin_disease1/doctor_dashboard.dart';
import 'package:skin_disease1/doctor_profile_setup.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<Widget> _getInitialScreen() async {
    // Check if admin is logged in
    final prefs = await SharedPreferences.getInstance();
    bool isAdminLoggedIn = prefs.getBool('isAdminLoggedIn') ?? false;
    
    if (isAdminLoggedIn) {
      return AdminDashboard();
    }

    // Check Firebase Auth for regular users
    User? user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return Login();
    }

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        await FirebaseAuth.instance.signOut();
        return Login();
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String role = userData['role'] ?? 'patient';

      if (role == 'doctor') {
        String status = userData['status'] ?? 'pending';
        
        if (status == 'pending' || status == 'rejected') {
          await FirebaseAuth.instance.signOut();
          return Login();
        }

        bool isProfileComplete = userData['isProfileComplete'] ?? false;
        if (!isProfileComplete) {
          return DoctorProfileSetupScreen();
        } else {
          return DoctorDashboard();
        }
      } else if (role == 'admin') {
        return AdminDashboard();
      } else {
        return ImagePickerPage();
      }
    } catch (e) {
      await FirebaseAuth.instance.signOut();
      return Login();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _getInitialScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Color(0xFFF5F7FA),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icon/logo.png',
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 24),
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B9AE1)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      color: Color(0xFF7F8C8D),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Login();
        }

        return snapshot.data ?? Login();
      },
    );
  }
}
