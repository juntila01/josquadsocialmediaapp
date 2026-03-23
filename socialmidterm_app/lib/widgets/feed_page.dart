import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Connection: Imports the individual post design to display in the list
import 'post_card.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // Logic: Uses a StreamBuilder to listen for real-time updates across the whole app
      body: StreamBuilder<QuerySnapshot>(
        // Connection: Queries the 'posts' collection in Firestore
        // Logic: Orders posts so the newest ones appear at the top (descending: true)
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // 1. Error Handling: Displays a message if Firestore fails (e.g., permission or index issues)
          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}",
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
            );
          }

          // 2. Loading State: Shows a spinner while the app first connects to the database
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 3. Empty State: Logic to handle cases where no one has posted anything yet
          final posts = snapshot.data?.docs ?? [];
          if (posts.isEmpty) {
            return Center(
              child: Text(
                "No posts yet. Start sharing your nature photos!",
                style: TextStyle(color: theme.hintColor),
              ),
            );
          }

          // 4. The Feed List: Builds a scrollable list of PostCards
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              // Logic: Grabs the data for a single post at the current index
              final doc = posts[index];
              final data = doc.data() as Map<String, dynamic>;
              final String postId = doc.id;

              // Connection: Sends the Firestore data fields into the PostCard widget
              return PostCard(
                postId: postId, // Logic: The unique Firestore document ID
                postUid: data['uid'] ?? '', // Connection: The ID of the user who created the post
                username: data['username'] ?? 'User',
                ImageUrl: data['ImageUrl'] ?? '', // Logic: Supports both Image and Video URLs
                caption: data['caption'] ?? '',
                profileImage: data['profileImage'] ?? '',
                postType: data['postType'] ?? 'image', // Logic: Tells PostCard whether to show Image or Video widget
                // Connection: Converts the likes count to a string for display
                likes: data['likes']?.toString() ?? '0',
              );
            },
          );
        },
      ),
    );
  }
}