import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Connection: Required to update the user's document
import 'package:firebase_auth/firebase_auth.dart'; // Connection: Used to identify which user is making changes

class EditProfileScreen extends StatefulWidget {
  // Logic: Receives the existing profile data to pre-fill the text fields
  final String currentUsername;
  final String currentProfileImage;

  const EditProfileScreen({
    Key? key,
    required this.currentUsername,
    required this.currentProfileImage
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _imageController;
  bool _isLoading = false; // UI: Tracks if the update is currently processing

  @override
  void initState() {
    super.initState();
    // Logic: Initialize controllers with the current data passed from the ProfileScreen
    _usernameController = TextEditingController(text: widget.currentUsername);
    _imageController = TextEditingController(text: widget.currentProfileImage);
  }

  // Logic: The primary function for saving new profile information
  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      // Connection: Updates the specific user document in the 'users' collection
      // Logic: trim() is used to remove any accidental leading or trailing spaces
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'username': _usernameController.text.trim(),
        'profileImage': _imageController.text.trim(),
      });

      if (mounted) {
        // Navigation: Closes the edit screen and returns to the profile
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Updated!")),
        );
      }
    } catch (e) {
      // Logic: Error handling for failed network requests or database permissions
      print("Update Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // UI: Input for changing the display name
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            const SizedBox(height: 20),
            // UI: Input for the image URL (used instead of a file picker for simplicity)
            TextField(
              controller: _imageController,
              decoration: const InputDecoration(labelText: "Profile Image URL"),
            ),
            const SizedBox(height: 30),
            // UI: Conditional display - shows a spinner while the database is updating
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _updateProfile,
              child: const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Logic: Standard cleanup for text controllers
    _usernameController.dispose();
    _imageController.dispose();
    super.dispose();
  }
}