import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Connection: Used for creating the user authentication account
import 'package:cloud_firestore/cloud_firestore.dart'; // Connection: Used to store extra user profile data
import '../widgets/custom_textfield.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Logic: Controllers to capture and manage the text input from the user
  final username = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  final dobController = TextEditingController();

  String? selectedGender;
  final genders = ["Male", "Female", "Other"];

  // UI: Local styling constants for the sign-up form
  final Color primaryColor = Colors.blue;
  final Color inputColor = Colors.grey.shade200;

  // UI: Helper for consistent input decoration across the birthdate and gender fields
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

  @override
  void dispose() {
    // Logic: Essential cleanup to free up memory when the user leaves the screen
    username.dispose();
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    dobController.dispose();
    super.dispose();
  }

  // UI/Logic: Opens a system calendar to select the birthdate and formats it for the text field
  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      dobController.text =
      "${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}";
    }
  }

  // Logic: The main function that registers a new user
  Future<void> signUpUser() async {
    // 1. Validation: Ensures all fields are filled and passwords match before calling Firebase
    if (username.text.isEmpty ||
        email.text.isEmpty ||
        password.text.isEmpty ||
        confirmPassword.text.isEmpty ||
        dobController.text.isEmpty ||
        selectedGender == null) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    if (password.text != confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    try {
      // 2. Connection: Creates the actual login credentials in Firebase Auth
      UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text,
      );

      String uid = userCredential.user!.uid;

      // 3. Connection: Saves the additional user details into the 'users' collection in Firestore
      // Logic: Uses the same 'uid' from Auth as the document ID to link both systems
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "username": username.text,
        "email": email.text,
        "gender": selectedGender,
        "dob": dobController.text,
        "profileImage": null, // Initialized as null; updated later in Profile/Edit screens
      });

      // 4. Navigation: Moves the user to the Login screen upon successful registration
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );

    } catch (e) {
      // Logic: Displays any Firebase-specific errors (e.g., "email-already-in-use")
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  "SIGN-UP",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),

                // Connection: Uses the CustomTextField widget for consistent UI
                CustomTextField(
                  hint: "Name",
                  icon: Icons.person,
                  controller: username,
                ),
                const SizedBox(height: 15),
                CustomTextField(
                  hint: "Email",
                  icon: Icons.email,
                  controller: email,
                ),
                const SizedBox(height: 15),
                CustomTextField(
                  hint: "Password",
                  icon: Icons.lock,
                  controller: password,
                  obscure: true,
                ),
                const SizedBox(height: 15),
                CustomTextField(
                  hint: "Confirm Password",
                  icon: Icons.lock,
                  controller: confirmPassword,
                  obscure: true,
                ),
                const SizedBox(height: 15),

                // UI: Read-only field that triggers the date picker on tap
                TextField(
                  controller: dobController,
                  readOnly: true,
                  decoration: inputStyle("Date Of Birth", Icons.calendar_today),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 15),

                // UI: Dropdown menu for gender selection
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  hint: const Text("Select Gender"),
                  items: genders.map((gender) {
                    return DropdownMenuItem(
                      value: gender,
                      child: Text(gender),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedGender = value;
                    });
                  },
                  decoration: inputStyle("Gender", Icons.person),
                ),
                const SizedBox(height: 25),

                // UI: Submit button that triggers the signUpUser logic
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: buttonStyle(),
                    onPressed: signUpUser,
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(fontSize: 18),
                    ),
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