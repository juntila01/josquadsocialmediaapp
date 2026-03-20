import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Connection: Essential for accessing post sub-collections
import 'package:firebase_auth/firebase_auth.dart'; // Connection: Used to identify the author of the comment

class CommentScreen extends StatefulWidget {
  // Logic: The unique ID of the post is required to locate its specific comments sub-collection
  final String postId;
  const CommentScreen({Key? key, required this.postId}) : super(key: key);

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  // Logic: Controller to capture the text typed by the user
  final TextEditingController _commentController = TextEditingController();
  final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Logic: Function to package user data and the comment text for Firestore
  void _submitComment() async {
    // 1. Validation: Prevents sending empty or whitespace-only comments
    if (_commentController.text.trim().isEmpty) return;

    // 2. Connection: Fetches the current user's latest profile data (username/image)
    // This ensures the comment displays the correct identity even if changed recently
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid)
        .get();

    String username = userDoc['username'] ?? 'User';
    String profileImage = userDoc['profileImage'] ?? '';

    // 3. Connection: Adds the new comment into the 'comments' sub-collection of the specific post
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add({
      'text': _commentController.text.trim(),
      'uid': currentUid,
      'username': username,
      'profileImage': profileImage,
      'timestamp': FieldValue.serverTimestamp(), // Logic: Uses server time for consistent sorting
    });

    // UI: Clears the input field after a successful send
    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Comments"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. LIST OF COMMENTS
          // Connection: Real-time listener that updates the list whenever a new comment is added
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('timestamp', descending: true) // Logic: Newest comments appear at the top
                  .snapshots(),
              builder: (context, snapshot) {
                // UI: Shows a loading spinner while waiting for the first data fetch
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                // UI: Displays a placeholder message if the post has no comments
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No comments yet."));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var data = snapshot.data!.docs[index];
                    return ListTile(
                      // UI: Displays the commenter's profile picture or a person icon fallback
                      leading: CircleAvatar(
                        backgroundImage: data['profileImage'].isNotEmpty
                            ? NetworkImage(data['profileImage'])
                            : null,
                        child: data['profileImage'].isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(data['username'],
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(data['text']),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          // 2. TEXT INPUT AREA
          // UI: Sticky bottom bar designed for easy typing and sending
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: "Write a comment...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25), // UI: Rounded "bubble" style
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                    ),
                  ),
                ),
                // UI: Send button that triggers the Firestore upload logic
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.indigo),
                  onPressed: _submitComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Logic: Freeing up the text controller resource
    _commentController.dispose();
    super.dispose();
  }
}