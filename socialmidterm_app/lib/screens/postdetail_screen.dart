import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/widgets/post_card.dart'; // Connection: Reuses your VideoPreviewWidget

class PostDetailScreen extends StatefulWidget {
  final QueryDocumentSnapshot post;

  const PostDetailScreen({Key? key, required this.post}) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();

  Map<String, dynamic> get postData => widget.post.data() as Map<String, dynamic>;

  // Logic: Function to toggle likes (Heart) in Firestore
  Future<void> toggleLike(List likedBy) async {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    DocumentReference postRef = FirebaseFirestore.instance.collection('posts').doc(widget.post.id);

    if (likedBy.contains(uid)) {
      await postRef.update({
        'likedBy': FieldValue.arrayRemove([uid])
      });
    } else {
      await postRef.update({
        'likedBy': FieldValue.arrayUnion([uid])
      });
    }
  }

  Future<void> postComment() async {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (_commentController.text.trim().isEmpty || uid.isEmpty) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final userData = userDoc.data() as Map<String, dynamic>;

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.post.id)
        .collection('comments')
        .add({
      'uid': uid,
      'username': userData['username'] ?? 'User',
      'profileImage': userData['profileImage'] ?? '',
      'text': _commentController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    _commentController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

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
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance.collection('posts').doc(widget.post.id).snapshots(),
                          builder: (context, snapshot) {
                            List likedBy = [];
                            if (snapshot.hasData && snapshot.data!.exists) {
                              var d = snapshot.data!.data() as Map<String, dynamic>;
                              likedBy = d.containsKey('likedBy') ? d['likedBy'] : [];
                            }

                            // UPDATED: Added GestureDetector to the Heart Icon
                            return Row(
                              children: [
                                GestureDetector(
                                  onTap: () => toggleLike(likedBy),
                                  child: Icon(
                                      likedBy.contains(currentUid) ? Icons.favorite : Icons.favorite_border,
                                      color: likedBy.contains(currentUid) ? Colors.red : null,
                                      size: 24
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text("${likedBy.length}", style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            );
                          },
                        ),
                        const SizedBox(width: 20),
                        // UPDATED: Added GestureDetector to scroll to/focus comment box
                        GestureDetector(
                            onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
                            child: const Icon(Icons.chat_bubble_outline, size: 24)
                        ),
                        const SizedBox(width: 5),
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
                        shrinkWrap: true,
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