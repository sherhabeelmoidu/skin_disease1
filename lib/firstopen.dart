import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skin_disease1/login.dart';

import 'package:skin_disease1/summery.dart';

class Login extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold( backgroundColor: Colors.black,
      
      appBar: AppBar(
        title: Text(
          'Skin Disease Detection',
          style: GoogleFonts.poppins(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (context)=> SkinDiseaseSummaryPage()));},
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue, // Button background
              foregroundColor: Colors.white, // Text color
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20), // Curved edges
              ),
            ),
            child: Text('Home'),
          ),
          SizedBox(width: 2,),
          TextButton(
            onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (context)=> LoginApp()));},
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue, // Button background
              foregroundColor: Colors.white, // Text color
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20), // Curved edges
              ),
            ),
            child: Text(
              'Login',
             
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/skin_disease.jpg', fit: BoxFit.cover),
          Container(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.5),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Skin Disease',
                  style: GoogleFonts.dancingScript(
                    fontSize: 40,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Enhanced Skin Disease Detection and Classification using Deep Learning',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 18, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
