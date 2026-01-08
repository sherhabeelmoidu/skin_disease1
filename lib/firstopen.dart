import 'package:flutter/material.dart';
import 'package:skin_disease1/login.dart';
import 'package:skin_disease1/signup.dart';
import 'package:skin_disease1/service.dart';

class Login extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Title
                Text(
                  'Detect Skin Diseases\nUsing AI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 30),
                // Illustration
                Container(
                  height: 280,
                  child: Image.asset('assets/image3.png', fit: BoxFit.contain),
                ),
                SizedBox(height: 30),
                // Subtitle
                Text(
                  'Detect Skin Diseases\nUsing AI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Get instant results & expert advice\nfor your skin concerns.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7F8C8D),
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 40),
                // Log In Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginApp()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3B9AE1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Text(
                      'Log In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignUp()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFF3B9AE1),
                      side: BorderSide(color: Color(0xFF3B9AE1), width: 2),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // Terms text
                Text(
                  'By continuing you agree to the Terms & Conditions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF95A5A6)),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
