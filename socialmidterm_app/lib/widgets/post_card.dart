import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';
import '/screens/comment_screen.dart';
import '/screens/user_profile_screen.dart';
import 'dart:async';

class PostCard extends StatelessWidget {
  // Logic: Data passed from FeedPage to display individual post details
  final String postId;
  final String postUid; // Connection: Used to navigate to the specific author's profile
  final String username;
  final String imageUrl; // Logic: Can be an Image URL or a Video URL based on postType
  final String caption;
  final String profileImage;
  final String likes;
  final String postType;

  const PostCard({
    Key? key,
    required this.postId,
    required this.postUid,
    required this.username,
    required this.imageUrl,
    required this.caption,
    required this.profileImage,
    required this.likes,
    this.postType = 'image',
  }) : super(key: key);

  // Logic: Handles the Like/Unlike functionality
  Future<void> _toggleLike() async {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    // Connection: References the specific document in the 'posts' collection
    DocumentReference postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
    DocumentSnapshot doc = await postRef.get();

    List<dynamic> likedBy = [];
    try { likedBy = doc.get('likedBy') ?? []; } catch (e) { likedBy = []; }

    // Logic: If user already liked it, remove them (Unlike); otherwise, add them (Like)
    if (likedBy.contains(uid)) {
      await postRef.update({'likedBy': FieldValue.arrayRemove([uid])});
    } else {
      await postRef.update({'likedBy': FieldValue.arrayUnion([uid])});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER ---
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: GestureDetector(
              // Connection: Opens the UserProfileScreen for the person who posted this
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: postUid))),
              child: CircleAvatar(
                radius: 20,
                backgroundImage: profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
                child: profileImage.isEmpty ? const Icon(Icons.person) : null,
              ),
            ),
            title: Text(username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            trailing: const Icon(Icons.more_vert),
          ),

          // --- CONTENT AREA ---
          if (imageUrl.isNotEmpty)
            ClipRRect(
              child: Container(
                width: double.infinity,
                height: 350,
                color: Colors.black,
                // Logic: Switches between static Image or the VideoPreviewWidget based on postType
                child: postType.toLowerCase() == 'video'
                    ? VideoPreviewWidget(videoUrl: imageUrl)
                    : Image.network(imageUrl, fit: BoxFit.cover),
              ),
            ),

          // --- ACTION BAR (Instagram Style) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                // LIKE BUTTON & COUNT
                // Connection: Listens to real-time changes in the specific post's 'likedBy' array
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('posts').doc(postId).snapshots(),
                  builder: (context, snapshot) {
                    List likedBy = [];
                    if (snapshot.hasData && snapshot.data!.exists) {
                      likedBy = (snapshot.data!.data() as Map<String, dynamic>)['likedBy'] ?? [];
                    }
                    bool isLiked = likedBy.contains(currentUid);
                    return Row(
                      children: [
                        IconButton(
                          icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : theme.iconTheme.color),
                          onPressed: _toggleLike,
                        ),
                        Text("${likedBy.length}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 8),

                // COMMENT BUTTON & COUNT
                // Connection: Listens to the 'comments' sub-collection inside the specific post
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('posts').doc(postId).collection('comments').snapshots(),
                  builder: (context, snapshot) {
                    int commentCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline),
                          // Connection: Navigates to CommentScreen to view/add comments
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CommentScreen(postId: postId))),
                        ),
                        Text("$commentCount", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    );
                  },
                ),
                const Spacer(),
                const IconButton(icon: Icon(Icons.bookmark_border), onPressed: null),
              ],
            ),
          ),

          // --- CAPTION ---
          if (caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
        ],
      ),
    );
  }
}

// Logic: A specialized StatefulWidget to handle inline video playback within the feed
class VideoPreviewWidget extends StatefulWidget {
  final String videoUrl;
  const VideoPreviewWidget({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _VideoPreviewWidgetState createState() => _VideoPreviewWidgetState();
}

class _VideoPreviewWidgetState extends State<VideoPreviewWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _showIcon = false; // Logic: Controls the play/pause icon fade-out
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Logic: Initializes the video, sets it to loop, and starts muted playback
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _isInitialized = true);
          _controller.setLooping(true);
          _controller.setVolume(0); // Starts muted for a better user experience
          _controller.play();
        }
      });
  }

  // Logic: Handles toggling play/pause and the temporary icon overlay
  void _onVideoTap() {
    if (!_controller.value.isInitialized) return;
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
      _showIcon = true;
    });
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _showIcon = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) return const Center(child: CircularProgressIndicator());

    return Stack(
      alignment: Alignment.center,
      children: [
        // UI: The actual video player
        Center(
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
        ),
        // UI: Transparent layer to capture tap gestures for play/pause
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _onVideoTap,
            child: Container(color: Colors.transparent),
          ),
        ),
        // UI: Centered play/pause icon overlay
        if (!_controller.value.isPlaying || _showIcon)
          IgnorePointer(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
              child: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                size: 50, color: Colors.white,
              ),
            ),
          ),
        // UI: Red progress bar at the bottom of the video
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: VideoProgressIndicator(_controller, allowScrubbing: true,
              colors: const VideoProgressColors(playedColor: Colors.red)),
        ),
        // UI: Mute/Unmute toggle button
        // Logic: Placed at the very end of the Stack so it stays on top of the GestureDetector
        Positioned(
          bottom: 10, right: 10,
          child: GestureDetector(
            onTap: () => setState(() => _controller.setVolume(_controller.value.volume == 0 ? 1 : 0)),
            child: CircleAvatar(
              radius: 18, backgroundColor: Colors.black54,
              child: Icon(_controller.value.volume == 0 ? Icons.volume_off : Icons.volume_up, size: 18, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Logic: Crucial to stop video and clean up memory when post is scrolled away
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }
}