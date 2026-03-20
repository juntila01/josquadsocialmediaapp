import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart'; // Logic: Required for the video thumbnail preview
import 'edit_profile_screen.dart';
import 'postdetail_screen.dart';
import 'chat_screen.dart';
import 'dart:async';

class UserProfileScreen extends StatelessWidget {
  final String userId; // Connection: Receives the UID of the user whose profile is being viewed

  const UserProfileScreen({Key? key, required this.userId}) : super(key: key);

  // Logic: Handles the mutual friend/follow relationship in Firestore
  Future<void> _toggleFriendship() async {
    final String myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (myUid.isEmpty || userId == myUid) return;

    // Connection: References for both the current user and the profile being viewed
    DocumentReference myRef = FirebaseFirestore.instance.collection('users').doc(myUid);
    DocumentReference targetRef = FirebaseFirestore.instance.collection('users').doc(userId);

    DocumentSnapshot myDoc = await myRef.get();
    List friends = [];
    try {
      // Logic: Defensive check to ensure we are treating the data as a List
      var data = myDoc.data() as Map<String, dynamic>;
      var rawFriends = data['friends'];
      friends = (rawFriends is List) ? rawFriends : [];
    } catch (e) {
      friends = [];
    }

    if (friends.contains(userId)) {
      // Logic: If already friends, remove the connection from both documents
      await myRef.update({'friends': FieldValue.arrayRemove([userId])});
      await targetRef.update({'friends': FieldValue.arrayRemove([myUid])});
    } else {
      // Logic: If not friends, add the connection to both documents
      await myRef.update({'friends': FieldValue.arrayUnion([userId])});
      await targetRef.update({'friends': FieldValue.arrayUnion([myUid])});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    // Logic: Determines if the profile belongs to the logged-in user to show "Edit" vs "Follow"
    final bool isMe = userId == currentUid;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: !isMe ? AppBar(title: const Text("Profile")) : null,
      body: StreamBuilder<DocumentSnapshot>(
        // Connection: Listens to the specific user's data (username, profile image, friends list)
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          var userData = userSnapshot.data!.data() as Map<String, dynamic>;
          String name = userData['username'] ?? 'User';
          String pic = userData['profileImage'] ?? '';

          return StreamBuilder<QuerySnapshot>(
            // Connection: Listens to all posts in the 'posts' collection where the UID matches this profile
            stream: FirebaseFirestore.instance
                .collection('posts')
                .where('uid', isEqualTo: userId)
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
                          if (isMe) const SizedBox(height: 40),
                          // UI: Profile Picture display with a fallback icon
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[300],
                            backgroundImage: pic.isNotEmpty ? NetworkImage(pic) : null,
                            child: pic.isEmpty ? Icon(Icons.person, size: 50, color: theme.iconTheme.color) : null,
                          ),
                          const SizedBox(height: 15),
                          Text(name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          // Logic: Stats row calculating Posts, total Likes (summed from all posts), and Friends count
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatColumn(context, postCount.toString(), "Posts"),
                              _buildStatColumn(
                                  context,
                                  postSnapshot.hasData
                                      ? postSnapshot.data!.docs.fold<int>(0, (sum, doc) {
                                    final d = doc.data() as Map<String, dynamic>;
                                    List likedBy = d.containsKey('likedBy') && d['likedBy'] is List
                                        ? d['likedBy']
                                        : [];
                                    return sum + likedBy.length;
                                  }).toString()
                                      : "0",
                                  "Likes"
                              ),
                              _buildStatColumn(
                                  context,
                                  (() {
                                    var friendsData = userData['friends'];
                                    // Logic: Crash-proof check for the Friends stat
                                    return (friendsData is List) ? friendsData.length.toString() : "0";
                                  })(),
                                  "Friends"
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Logic: Conditional UI - shows "Edit Profile" for owner, "Follow/Chat" for others
                          isMe ? _buildEditButton(context, name, pic, theme) : _buildSocialButtons(context, userId, currentUid, name, theme),
                          Divider(height: 40, color: theme.dividerColor),
                        ],
                      ),
                    ),
                  ),
                ],
                // Logic: The bottom half shows the grid of images/videos posted by the user
                body: _buildPostGrid(context, postSnapshot),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPostGrid(BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return Center(child: Text("No posts found.", style: TextStyle(color: Theme.of(context).hintColor)));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2,
      ),
      itemCount: snapshot.data!.docs.length,
      itemBuilder: (context, index) {
        var postDoc = snapshot.data!.docs[index];
        final data = postDoc.data() as Map<String, dynamic>;

        String postType = data.containsKey('postType') ? data['postType'] : 'image';
        String imageUrl = data.containsKey('ImageUrl') ? data['ImageUrl'] : '';
        bool isVideo = postType.toLowerCase() == 'video';

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          // Connection: Navigates to the full post view when a thumbnail is tapped
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PostDetailScreen(post: postDoc)),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Logic: Displays the VideoGridThumbnail helper if it's a video, otherwise a standard Image
              isVideo
                  ? IgnorePointer(child: VideoGridThumbnail(videoUrl: imageUrl))
                  : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.black87,
                  child: const Icon(Icons.broken_image, color: Colors.white24),
                ),
              ),
              // UI: Overlay icon to indicate the post is a video
              if (isVideo)
                const Positioned(
                  top: 5,
                  right: 5,
                  child: Icon(Icons.videocam, color: Colors.white, size: 20),
                ),
            ],
          ),
        );
      },
    );
  }

  // UI: Style for the "Edit Profile" button (only visible to the profile owner)
  Widget _buildEditButton(BuildContext context, String name, String img, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(currentUsername: name, currentProfileImage: img))),
        child: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // UI: Style for interaction buttons (visible when viewing someone else's profile)
  Widget _buildSocialButtons(BuildContext context, String targetId, String myUid, String name, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          // Connection: Listens to the current user's document to check if the target is already a friend
          child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(myUid).snapshots(),
              builder: (context, snapshot) {
                List friends = [];
                if (snapshot.hasData && snapshot.data!.exists) {
                  var data = snapshot.data!.data() as Map<String, dynamic>;
                  // Logic: Crash-proof check. Converts raw data to list or empty list if wrong type.
                  var rawFriends = data['friends'];
                  friends = (rawFriends is List) ? rawFriends : [];
                }
                bool isFriend = friends.contains(targetId);

                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    // UI: Changes button appearance based on friendship status
                      backgroundColor: isFriend ? Colors.grey[700] : theme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                  ),
                  onPressed: _toggleFriendship, // Logic: Triggers the mutual add/remove function
                  child: Text(isFriend ? "Friends" : "Add Friend", style: const TextStyle(color: Colors.white)),
                );
              }
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          // Connection: Navigates to ChatScreen to message this specific user
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(receiverId: targetId, receiverName: name))),
          icon: const Icon(Icons.chat_bubble_outline),
        ),
      ],
    );
  }

  // UI: Helper to create the bold stat numbers (Posts, Likes, Friends)
  Widget _buildStatColumn(BuildContext context, String value, String label) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: theme.hintColor)),
      ],
    );
  }
}

// Logic: A specialized helper widget that initializes a VideoPlayer just to show the first frame as a grid thumbnail
class VideoGridThumbnail extends StatefulWidget {
  final String videoUrl;
  const VideoGridThumbnail({Key? key, required this.videoUrl}) : super(key: key);
  @override
  _VideoGridThumbnailState createState() => _VideoGridThumbnailState();
}

class _VideoGridThumbnailState extends State<VideoGridThumbnail> {
  late VideoPlayerController _controller;
  bool _init = false;
  @override
  void initState() {
    super.initState();
    // Connection: Links to the video URL stored in Firestore 'ImageUrl' field
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) => setState(() => _init = true));
  }
  @override
  Widget build(BuildContext context) => _init
      ? FittedBox(fit: BoxFit.cover, clipBehavior: Clip.hardEdge, child: SizedBox(width: _controller.value.size.width, height: _controller.value.size.height, child: VideoPlayer(_controller)))
      : Container(color: Colors.black12);
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
}