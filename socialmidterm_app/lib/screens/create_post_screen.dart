import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Connection: Required to save the new post document to the database
import 'package:firebase_auth/firebase_auth.dart'; // Connection: Used to link the post to the current user's UID

class CreatePostScreen extends StatefulWidget {
  // Logic: User details passed from the HomeScreen to attach to the post for the feed display
  final String username;
  final String? profileImage;

  CreatePostScreen({required this.username, this.profileImage});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  // Logic: Controllers for the content URL and the user's caption text
  final _urlController = TextEditingController();
  final _captionController = TextEditingController();

  // Logic: Default content type is 'image' unless the user toggles it to 'video'
  String _selectedType = 'image';
  bool isPosting = false; // UI: Prevents multiple submissions if the button is tapped quickly

  // Logic: The main function to validate and upload the post to Firestore
  Future<void> submitPost() async {
    final String url = _urlController.text.trim();

    // 1. Validation: Ensures a content link exists before attempting a database write
    if (url.isEmpty) return;

    setState(() => isPosting = true);

    try {
      final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

      // 2. Connection: Adds a new document to the 'posts' collection
      await FirebaseFirestore.instance.collection('posts').add({
        'ImageUrl': url, // Connection: Used by Feed/Grid to load the media
        'caption': _captionController.text.trim(),
        'username': widget.username,
        'profileImage': widget.profileImage ?? "",
        'uid': uid,
        'postType': _selectedType, // Logic: Saved so the Feed knows whether to use an Image or Video player
        'likedBy': [], // Logic: Initialized as an empty list to track specific users who like the post
        'timestamp': FieldValue.serverTimestamp(), // Logic: Precise server time for chronological sorting in the feed
      });

      // 3. Navigation: Returns to the Home screen after successful upload
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // Logic: Displays a snackbar if the network or database permission fails
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Post")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- TYPE SELECTION ---
            // UI: Horizontal choice chips to let the user specify their media format
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text("Image"),
                  selected: _selectedType == 'image',
                  onSelected: (val) => setState(() => _selectedType = 'image'),
                ),
                const SizedBox(width: 15),
                ChoiceChip(
                  label: const Text("Video"),
                  selected: _selectedType == 'video',
                  onSelected: (val) => setState(() => _selectedType = 'video'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // URL INPUT
            // UI: Dynamic labels and icons that adjust based on the selected media type
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: _selectedType == 'image' ? "Image URL" : "Video URL",
                prefixIcon: Icon(_selectedType == 'image' ? Icons.image : Icons.videocam),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            // CAPTION INPUT
            // UI: Standard text field for the post description
            TextField(
              controller: _captionController,
              decoration: const InputDecoration(
                labelText: "Caption",
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),

            // UI: Conditional display - shows a spinner or the submit button
            isPosting
                ? const CircularProgressIndicator()
                : SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: submitPost,
                child: const Text("Post Now", style: TextStyle(fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Logic: Freeing up resources when the user cancels or finishes a post
    _urlController.dispose();
    _captionController.dispose();
    super.dispose();
  }
}