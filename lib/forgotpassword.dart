import 'dart:math';

import 'package:flutter/material.dart';
import 'package:skin_disease1/service.dart';

class forgot  extends StatelessWidget {
  
TextEditingController emailcontroller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Center(
            child: Text('Forgot Password Page'),
          ),
          TextField(controller: emailcontroller, decoration: const InputDecoration(hintText: 'Email'),),
          ElevatedButton(onPressed: () {
            forgotpassword(email :emailcontroller.text,context: context);
          }, child: Text("sent link"))
        ],
      ),
    );
  }
}