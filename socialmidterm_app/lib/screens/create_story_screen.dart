import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Connection: Used to save the story metadata to the database
import 'package:firebase_auth/firebase_auth.dart'; // Connection: Identifies which user is posting the story

class CreateStoryScreen extends StatefulWidget {
  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  // Logic: Controller for the external URL input (Image or Video)
  final _urlController = TextEditingController();

  // Logic: Default settings for the story behavior
  int _selectedDuration = 24; // Default expiration is 24 hours
  String _selectedType = 'image'; // Default content type
  bool isPosting = false; // UI: Prevents double-tapping the post button

  // Logic: The main function to calculate expiry and upload story data
  Future<void> _postStory() async {
    final String url = _urlController.text.trim();

    // 1. Validation: Ensures a URL is provided before proceeding
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please paste a $_selectedType URL first")),
      );
      return;
    }

    setState(() => isPosting = true);

    try {
      final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

      // Logic: Calculates the exact point in time when this story should disappear
      DateTime expiryDate = DateTime.now().add(Duration(hours: _selectedDuration));

      // 2. Connection: Saves the entry to the "storiess" collection
      // Note: Using 'storiess' matches the collection name called in HomeScreen
      await FirebaseFirestore.instance.collection('storiess').add({
        'imageUrl': url, // Connection: Field used by SidebarUsers/StoryView for the content link
        'type': _selectedType, // Logic: 'image' or 'video' - determines which player to load later
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(), // Logic: Precise server-side creation time
        'expiresAt': Timestamp.fromDate(expiryDate), // Connection: HomeScreen uses this for filtering
        'durationHours': _selectedDuration,
      });

      // 3. Navigation: Returns the user to the Home/Feed upon success
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // Logic: Generic error handling for database failures
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to post story: $e")),
      );
    } finally {
      if (mounted) setState(() => isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Story"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Share a Moment", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // --- TYPE SELECTION (Image vs Video) ---
            // UI: Allows the user to toggle the story format before posting
            Row(
              children: [
                const Text("Content Type: ", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text("Image"),
                  selected: _selectedType == 'image',
                  onSelected: (val) => setState(() => _selectedType = 'image'),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text("Video"),
                  selected: _selectedType == 'video',
                  onSelected: (val) => setState(() => _selectedType = 'video'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // UI: Dynamic URL input field that changes labels based on Content Type
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: _selectedType == 'image' ? "Image URL" : "Video URL",
                hintText: _selectedType == 'image' ? "https://...jpg" : "https://...mp4",
                prefixIcon: Icon(_selectedType == 'image' ? Icons.image : Icons.videocam),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),

            const SizedBox(height: 30),
            const Text("Disappear After:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),

            // UI: Horizontal list of duration options (2 to 24 hours)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [2, 6, 12, 24].map((hours) {
                return ChoiceChip(
                  label: Text("$hours hrs"),
                  selected: _selectedDuration == hours,
                  selectedColor: Colors.indigo,
                  labelStyle: TextStyle(color: _selectedDuration == hours ? Colors.white : Colors.black),
                  onSelected: (selected) { if (selected) setState(() => _selectedDuration = hours); },
                );
              }).toList(),
            ),

            const Spacer(),

            // UI: Conditional loading indicator or Post button
            isPosting
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _postStory,
                child: const Text("Post Story", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Logic: Freeing up the text controller resource
    _urlController.dispose();
    super.dispose();
  }
}