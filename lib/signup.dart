import 'package:flutter/material.dart';
import 'package:skin_disease1/login.dart';
import 'package:skin_disease1/service.dart';

class SignUp extends StatefulWidget {
  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {TextEditingController namecontroller = TextEditingController();

  TextEditingController emailcontroller = TextEditingController();

  TextEditingController password1controller = TextEditingController();
  bool rememberMe = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 17, 15, 15),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color:Colors.blueGrey, blurRadius: 10)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Sign up",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  "Sign up to continue",
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                SizedBox(height: 24),
                TextField(controller: namecontroller,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(controller: emailcontroller,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(controller: password1controller,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: rememberMe,
                      onChanged: (val) {
                        setState(() {
                          rememberMe = val ?? false;
                        });
                      },
                    ),
                    Text("Remember me"),
                  ],
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                  onPressed: () { reg(
                  email: emailcontroller.text,
                 
                  password1: password1controller.text,
                  context: context,
                );
                    // Handle sign-up logic
                  },
                  child: Text("Sign up"),
                ),
                SizedBox(height: 16),
                Text("ACCESS QUICKLY"),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(onPressed: () {}, child: Text("Google")),
                    OutlinedButton(onPressed: () {}, child: Text("LinkedIn")),
                    OutlinedButton(onPressed: () {}, child: Text("SSO")),
                  ],
                ),
                SizedBox(height: 16),
                GestureDetector(
                  onTap: () {Navigator.push(context, MaterialPageRoute(builder: (context)=> LoginApp()));
                    // Navigate to Sign In page
                  },
                  child: Text(
                    "Already have an account? Sign in",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}