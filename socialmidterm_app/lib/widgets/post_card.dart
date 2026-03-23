import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';
import '/screens/comment_screen.dart';
import '/screens/user_profile_screen.dart';
import 'dart:async';

class PostCard extends StatefulWidget {
  final String postId;
  final String postUid;
  final String username;
  final String ImageUrl;
  final String caption;
  final String profileImage;
  final String likes;
  final String postType;

  const PostCard({
    Key? key,
    required this.postId,
    required this.postUid,
    required this.username,
    required this.ImageUrl,
    required this.caption,
    required this.profileImage,
    required this.likes,
    this.postType = 'image',
  }) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  // Logic: Function to update Firestore. Using 'void' instead of 'Future' for the button
  // to ensure it triggers immediately without waiting for the network.
  void _toggleLike() async {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    DocumentReference postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);

    try {
      DocumentSnapshot doc = await postRef.get();
      List<dynamic> likedBy = (doc.data() as Map<String, dynamic>)['likedBy'] ?? [];

      if (likedBy.contains(uid)) {
        await postRef.update({'likedBy': FieldValue.arrayRemove([uid])});
      } else {
        await postRef.update({'likedBy': FieldValue.arrayUnion([uid])});
      }
    } catch (e) {
      debugPrint("Like error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header (Username/Profile)
          ListTile(
            leading: CircleAvatar(
              backgroundImage: widget.profileImage.isNotEmpty ? NetworkImage(widget.profileImage) : null,
              child: widget.profileImage.isEmpty ? const Icon(Icons.person) : null,
            ),
            title: Text(widget.username, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),

          // 2. Media Area (The likely culprit for blocking clicks)
          if (widget.ImageUrl.isNotEmpty)
            SizedBox(
              height: 350,
              width: double.infinity,
              child: ClipRRect(
                child: widget.postType.toLowerCase() == 'video'
                    ? VideoPreviewWidget(videoUrl: widget.ImageUrl)
                    : Image.network(widget.ImageUrl, fit: BoxFit.cover),
              ),
            ),

          // 3. Action Bar (Explicitly using InkWell for better hit-testing)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // LIKE BUTTON
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('posts').doc(widget.postId).snapshots(),
                  builder: (context, snapshot) {
                    List likedBy = [];
                    if (snapshot.hasData && snapshot.data!.exists) {
                      likedBy = (snapshot.data!.data() as Map<String, dynamic>)['likedBy'] ?? [];
                    }
                    bool isLiked = likedBy.contains(currentUid);

                    return InkWell(
                      onTap: _toggleLike, // Logic: Trigger the like function
                      child: Padding(
                        padding: const EdgeInsets.all(10.0), // UI: Increased tap area
                        child: Row(
                          children: [
                            Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : theme.iconTheme.color,
                              size: 30,
                            ),
                            const SizedBox(width: 6),
                            Text("${likedBy.length}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(width: 15),

                // COMMENT BUTTON
                InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CommentScreen(postId: widget.postId))),
                  child: const Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Icon(Icons.chat_bubble_outline, size: 28),
                  ),
                ),
              ],
            ),
          ),

          // 4. Caption
          if (widget.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text("${widget.username}: ${widget.caption}"),
            ),
        ],
      ),
    );
  }
}

// Logic: Simplified Video Widget to prevent touch-blocking
class VideoPreviewWidget extends StatefulWidget {
  final String videoUrl;
  const VideoPreviewWidget({Key? key, required this.videoUrl}) : super(key: key);
  @override
  _VideoPreviewWidgetState createState() => _VideoPreviewWidgetState();
}

class _VideoPreviewWidgetState extends State<VideoPreviewWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {});
        _controller.setLooping(true);
        _controller.setVolume(0);
        _controller.play();
      });
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) return const Center(child: CircularProgressIndicator());

    // Logic: Use a simple GestureDetector only on the VIDEO area
    return GestureDetector(
      onTap: () => setState(() => _controller.value.isPlaying ? _controller.pause() : _controller.play()),
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_controller),
          if (!_controller.value.isPlaying)
            const Icon(Icons.play_arrow, size: 50, color: Colors.white),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}