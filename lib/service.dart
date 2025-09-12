
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:skin_disease1/afterlogin.dart';

Future<void> reg({
  required String email,
  required String password1,
 
  required BuildContext context,
}) async {  
  try {
    UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password1);
    User? user = userCredential.user;
    await FirebaseFirestore.instance.collection('user').doc(user?.uid).set({
      "email": email,
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("user created successfully")));
  } catch (e) {
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
  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password1,
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("logined")));
  Navigator.push(context, MaterialPageRoute(builder:(context)=>ImagePickerPage()));
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.toString())));
  }
}

