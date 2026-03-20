import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Connection: Handles the actual sign-in credentials check
import 'package:cloud_firestore/cloud_firestore.dart'; // Connection: Fetches the user's specific profile info (like username)
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Logic: Controllers to capture the user's login credentials
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // UI: Consistency constants to match the JoshquadSocial branding
  final Color primaryColor = Colors.blue;
  final Color inputColor = Colors.grey.shade200;

  // UI: Helper for consistent text field decoration (shared with the signup screen style)
  InputDecoration inputStyle(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey),
      filled: true,
      fillColor: inputColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
    );
  }

  // UI: Reusable style for the main Login button
  ButtonStyle buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  // Logic: The primary function for verifying user credentials
  Future<void> loginUser() async {
    // 1. Validation: Simple check to ensure the user didn't leave fields blank
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password")),
      );
      return;
    }

    try {
      // 2. Connection: Sends email/password to Firebase Auth for verification
      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      String uid = userCredential.user!.uid;

      // 3. Connection: Once authenticated, reach out to Firestore 'users' collection
      // Logic: Pulls the specific document matching the 'uid' to get the username for the HomeScreen
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      String username = userDoc['username'];

      // 4. Navigation: Moves the user to the HomeScreen and removes the Login screen from the history
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(username: username),
        ),
      );

    } catch (e) {
      // Logic: Displays the specific error (e.g., "wrong password" or "user not found")
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: $e")),
      );
    }
  }

  @override
  void dispose() {
    // Logic: Freeing up resources when the user leaves the screen
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // UI: Main Header
            const Text(
              "LOGIN",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            // UI: Email Input
            TextField(
              controller: emailController,
              decoration: inputStyle("Email", Icons.email),
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 15),

            // UI: Password Input with text obscuring for security
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: inputStyle("Password", Icons.lock),
            ),

            const SizedBox(height: 25),

            // UI: Action button to trigger the loginUser logic
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: buttonStyle(),
                onPressed: loginUser,
                child: const Text(
                  "Login",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}