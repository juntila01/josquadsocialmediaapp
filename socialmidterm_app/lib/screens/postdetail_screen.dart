import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/widgets/post_card.dart'; // Connection: Reuses your VideoPreviewWidget for consistent playback

class PostDetailScreen extends StatefulWidget {
  // Logic: Receives the entire QueryDocumentSnapshot from the GridView or Feed
  final QueryDocumentSnapshot post;

  const PostDetailScreen({Key? key, required this.post}) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  // Logic: Controller to manage the text typed in the bottom comment bar
  final TextEditingController _commentController = TextEditingController();

  // --- SAFE DATA PARSING ---
  // Logic: Helper to extract map data from the Firestore document
  Map<String, dynamic> get postData => widget.post.data() as Map<String, dynamic>;

  // Logic: Function to upload a new comment to Firestore
  Future<void> postComment() async {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    // Validation: Prevents empty comments or guest users from posting
    if (_commentController.text.trim().isEmpty || uid.isEmpty) return;

    // Connection: Fetches the current user's profile info to attach to the comment
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final userData = userDoc.data() as Map<String, dynamic>;

    // Connection: Adds the comment to a 'comments' sub-collection inside the specific post document
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.post.id)
        .collection('comments')
        .add({
      'uid': uid,
      'username': userData['username'] ?? 'User',
      'profileImage': userData['profileImage'] ?? '',
      'text': _commentController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(), // Logic: Uses server time for accurate sorting
    });

    // UI: Clears the input and hides the keyboard after sending
    _commentController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Logic: Safety checks to prevent crashes if certain fields are missing in older database entries
    final String postType = postData.containsKey('postType') ? postData['postType'] : 'image';
    final String imageUrl = postData.containsKey('ImageUrl') ? postData['ImageUrl'] : '';
    final String username = postData.containsKey('username') ? postData['username'] : 'User';
    final String caption = postData.containsKey('caption') ? postData['caption'] : '';

    return Scaffold(
      appBar: AppBar(title: const Text("Post")),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. THE MEDIA CONTENT
                  // UI: Large display area that switches between Image and VideoPlayer
                  Container(
                    width: double.infinity,
                    height: 350,
                    color: Colors.black,
                    child: postType.toLowerCase() == 'video'
                        ? VideoPreviewWidget(videoUrl: imageUrl)
                        : Image.network(imageUrl, fit: BoxFit.cover,
                        errorBuilder: (context, e, s) => const Icon(Icons.broken_image, color: Colors.white)),
                  ),

                  // 2. ACTION BAR (Like & Comment Counts)
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        // Connection: Real-time listener for the like count on this specific post
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance.collection('posts').doc(widget.post.id).snapshots(),
                          builder: (context, snapshot) {
                            List likedBy = [];
                            if (snapshot.hasData && snapshot.data!.exists) {
                              var d = snapshot.data!.data() as Map<String, dynamic>;
                              likedBy = d.containsKey('likedBy') ? d['likedBy'] : [];
                            }
                            return Row(
                              children: [
                                const Icon(Icons.favorite, color: Colors.red, size: 24),
                                const SizedBox(width: 5),
                                Text("${likedBy.length}", style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            );
                          },
                        ),
                        const SizedBox(width: 20),
                        const Icon(Icons.chat_bubble_outline, size: 24),
                        const SizedBox(width: 5),
                        // Connection: Real-time listener for the number of documents in the comments sub-collection
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('posts').doc(widget.post.id).collection('comments').snapshots(),
                          builder: (context, snapshot) => Text(
                            "${snapshot.hasData ? snapshot.data!.docs.length : 0}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. CAPTION
                  if (caption.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodyMedium,
                          children: [
                            TextSpan(text: "$username ", style: const TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: caption),
                          ],
                        ),
                      ),
                    ),

                  const Divider(),

                  // 4. COMMENTS LIST
                  // Connection: Fetches comments for this post, sorted newest first
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .doc(widget.post.id)
                        .collection('comments')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                      if (snapshot.data!.docs.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Text("No comments yet."));

                      return ListView.builder(
                        shrinkWrap: true, // Logic: Allows the list to live inside a ScrollView
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var comment = snapshot.data!.docs[index];
                          return ListTile(
                            leading: CircleAvatar(
                              radius: 15,
                              backgroundImage: comment['profileImage'].toString().isNotEmpty
                                  ? NetworkImage(comment['profileImage']) : null,
                              child: comment['profileImage'].toString().isEmpty ? const Icon(Icons.person, size: 15) : null,
                            ),
                            title: Text(comment['username'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text(comment['text']),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 5. COMMENT INPUT
          // UI: Sticky bottom bar for quick typing and sending
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: theme.cardColor, border: Border(top: BorderSide(color: theme.dividerColor))),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(hintText: "Add a comment...", border: InputBorder.none),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send, color: Colors.blue), onPressed: postComment),
              ],
            ),
          ),
        ],
      ),
    );
  }
}