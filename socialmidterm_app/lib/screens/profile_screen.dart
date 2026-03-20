import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart'; // Logic: Required for the video preview in the grid
import 'edit_profile_screen.dart';
import 'postdetail_screen.dart';

class ProfileScreen extends StatelessWidget {
  // Logic: Initial data passed from HomeScreen, though StreamBuilder will keep this updated
  final String username;
  final String profileImage;

  const ProfileScreen({
    Key? key,
    required this.username,
    required this.profileImage
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Connection: Gets the current logged-in user's ID to fetch their specific data
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: StreamBuilder<DocumentSnapshot>(
        // Connection: Listens for real-time changes to the user's profile (name, image, friends list)
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, userSnapshot) {
          String displayUsername = username;
          String displayImage = profileImage;

          // Logic: If Firestore data is available, override the initial passed values
          if (userSnapshot.hasData && userSnapshot.data!.exists) {
            var data = userSnapshot.data!.data() as Map<String, dynamic>;
            displayUsername = data['username'] ?? username;
            displayImage = data['profileImage'] ?? profileImage;
          }

          return StreamBuilder<QuerySnapshot>(
            // Connection: Fetches all posts from the 'posts' collection that belong to this user
            stream: FirebaseFirestore.instance
                .collection('posts')
                .where('uid', isEqualTo: uid)
                .snapshots(),
            builder: (context, postSnapshot) {
              int postCount = postSnapshot.hasData ? postSnapshot.data!.docs.length : 0;

              return NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          // UI: Displays the profile picture with a grey fallback if empty
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[300],
                            backgroundImage: displayImage.isNotEmpty ? NetworkImage(displayImage) : null,
                            child: displayImage.isEmpty
                                ? Icon(Icons.person, size: 50, color: theme.iconTheme.color)
                                : null,
                          ),
                          const SizedBox(height: 15),
                          Text(
                            displayUsername,
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          // Logic: Stats row calculating Posts count, total Likes received, and Friends count
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatColumn(context, postCount.toString(), "Posts"),
                              _buildStatColumn(
                                  context,
                                  postSnapshot.hasData
                                      ? postSnapshot.data!.docs.fold<int>(0, (sum, doc) {
                                    // Logic: Iterates through each post to sum up the 'likedBy' array lengths
                                    List likedBy = [];
                                    try { likedBy = doc.get('likedBy') ?? []; } catch (e) { likedBy = []; }
                                    return sum + likedBy.length;
                                  }).toString()
                                      : "0",
                                  "Likes"
                              ),
                              _buildStatColumn(
                                  context,
                                  userSnapshot.hasData && userSnapshot.data!.exists
                                      ? (() {
                                    var data = userSnapshot.data!.data() as Map<String, dynamic>;
                                    var friendsData = data['friends'];
                                    // Logic: Counts items in the 'friends' array if it exists
                                    if (friendsData is List) {
                                      return friendsData.length.toString();
                                    } else {
                                      return "0";
                                    }
                                  })()
                                      : "0",
                                  "Friends"
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // UI: Full-width button to navigate to the EditProfileScreen
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditProfileScreen(
                                      currentUsername: displayUsername,
                                      currentProfileImage: displayImage,
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                  "Edit Profile",
                                  style: TextStyle(color: Colors.white)
                              ),
                            ),
                          ),
                          Divider(height: 40, color: theme.dividerColor),
                        ],
                      ),
                    ),
                  ),
                ],
                // Logic: Displays the grid of uploaded images and videos
                body: _buildPostGrid(context, postSnapshot),
              );
            },
          );
        },
      ),
    );
  }

  // UI: Generates a 3-column grid of the user's posts
  Widget _buildPostGrid(BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return Center(
        child: Text(
          "No posts found for this user.",
          style: TextStyle(color: Theme.of(context).hintColor),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: snapshot.data!.docs.length,
      itemBuilder: (context, index) {
        var postDoc = snapshot.data!.docs[index];
        final data = postDoc.data() as Map<String, dynamic>;

        String imgUrl = data['ImageUrl'] ?? "";
        String postType = data.containsKey('postType') ? data['postType'] : "image";
        bool isVideo = postType.toLowerCase() == 'video';

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          // Connection: Opens the PostDetailScreen to view the full post content
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostDetailScreen(post: postDoc),
              ),
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Logic: Switches between the VideoGridThumbnail or standard NetworkImage
              isVideo
                  ? IgnorePointer(child: VideoGridThumbnail(videoUrl: imgUrl))
                  : Image.network(
                imgUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
              // UI: Small camera icon to indicate a video post in the grid
              if (isVideo)
                const Positioned(
                  top: 5,
                  right: 5,
                  child: Icon(Icons.videocam, color: Colors.white, size: 18),
                ),
            ],
          ),
        );
      },
    );
  }

  // UI: Helper to create the bold stat layout
  Widget _buildStatColumn(BuildContext context, String value, String label) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        ),
        Text(
            label,
            style: TextStyle(color: theme.hintColor)
        ),
      ],
    );
  }
}

// Logic: Handles the "first frame" preview for video posts in the profile grid
class VideoGridThumbnail extends StatefulWidget {
  final String videoUrl;
  const VideoGridThumbnail({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _VideoGridThumbnailState createState() => _VideoGridThumbnailState();
}

class _VideoGridThumbnailState extends State<VideoGridThumbnail> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Connection: Initializes the video player just enough to show a frame in the grid
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) setState(() => _isInitialized = true);
      });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) return Container(color: Colors.black12);
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: _controller.value.size.width,
        height: _controller.value.size.height,
        child: VideoPlayer(_controller),
      ),
    );
  }

  @override
  void dispose() {
    // Logic: Frees up video resources once the grid item is off-screen
    _controller.dispose();
    super.dispose();
  }
}