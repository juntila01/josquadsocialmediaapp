import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SidebarUsers extends StatelessWidget {
  // Logic: Data passed from HomeScreen to populate the vertical sidebar
  final String? myProfile;
  final List<DocumentSnapshot> otherUsers; // Connection: List of all users from 'users' collection
  final Map<String, String> activeStoriesByUid; // Connection: Map of UIDs that have active entries in 'storiess' collection
  final Map<String, int>? unreadCounts; // Connection: Calculates unread dots based on 'chats' collection state
  final VoidCallback? onMyProfileTap;
  final VoidCallback? onAddStoryTap;
  final Function(String)? onFriendTap; // Logic: Navigates to either StoryView or UserProfile
  final Uint8List? pickedLocalImage;
  final File? pickedLocalImageFile;
  final bool isUploading;

  const SidebarUsers({
    Key? key,
    required this.myProfile,
    required this.otherUsers,
    required this.activeStoriesByUid,
    this.unreadCounts,
    this.onMyProfileTap,
    this.onAddStoryTap,
    this.onFriendTap,
    this.pickedLocalImage,
    this.pickedLocalImageFile,
    this.isUploading = false,
  }) : super(key: key);

  // Logic: Deletes the current user's story from Firestore 'storiess' collection
  Future<void> _deleteMyStory(BuildContext context) async {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Story?"),
        content: const Text("This will remove your story for everyone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      // Connection: Queries 'storiess' collection to find docs matching current UID
      var query = await FirebaseFirestore.instance.collection('storiess').where('uid', isEqualTo: uid).get();
      for (var doc in query.docs) { await doc.reference.delete(); }
    }
  }

  // Logic: Handles profile images whether they are URLs, Base64 strings, or null
  ImageProvider? _getProfileImage(String? image) {
    if (image == null || image.isEmpty) return null;
    if (image.startsWith('http')) return NetworkImage(image);
    try { return MemoryImage(base64Decode(image)); } catch (e) { return null; }
  }

  @override
  Widget build(BuildContext context) {
    final String myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    bool hasMyStory = activeStoriesByUid.containsKey(myUid);

    return Container(
      width: 85, // Logic: Fixed width for the vertical sidebar layout
      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A1A1A) : Colors.grey[200],
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        children: [
          // Logic: Current user's avatar at the top of the sidebar
          _buildAvatarWithRing(
            context: context,
            imageUrl: myProfile,
            isMe: true,
            hasStory: hasMyStory,
            onTap: onMyProfileTap,
            onLongPress: hasMyStory ? () => _deleteMyStory(context) : null,
            child: _buildMyProfileExtras(),
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(thickness: 1, indent: 10, endIndent: 10)),

          // Logic: Maps through the list of other users to create the friend list
          ...otherUsers.map((userDoc) {
            final fUid = userDoc.id;
            final data = userDoc.data() as Map<String, dynamic>;
            final fPic = data['profileImage'] ?? '';
            final count = unreadCounts?[fUid] ?? 0;
            final hasStory = activeStoriesByUid.containsKey(fUid);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildAvatarWithRing(
                context: context,
                imageUrl: fPic,
                isMe: false,
                hasStory: hasStory, // Logic: Displays the colorful ring if UID exists in activeStoriesByUid
                onTap: () => onFriendTap?.call(fUid),
                badgeCount: count, // Logic: Displays the red notification dot for unread messages
              ),
            );
          }),
        ],
      ),
    );
  }

  // UI: The "+" icon button for adding a new story
  Widget _buildMyProfileExtras() {
    return Stack(
      children: [
        if (isUploading) const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        Positioned(
          bottom: 0, right: 0,
          child: GestureDetector(
            onTap: onAddStoryTap,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                child: const Icon(Icons.add, size: 10, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // UI: Reusable widget for avatars that includes the story gradient ring and unread badges
  Widget _buildAvatarWithRing({
    required BuildContext context, required String? imageUrl, required bool isMe,
    required bool hasStory, required VoidCallback? onTap, VoidCallback? onLongPress,
    int badgeCount = 0, Widget? child,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Logic: The colorful Instagram-style gradient only shows if hasStory is true
              gradient: hasStory ? const LinearGradient(colors: [Colors.purple, Colors.orange, Colors.yellow]) : null,
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A1A1A) : Colors.white,
              child: CircleAvatar(
                radius: 25,
                backgroundColor: Colors.grey[300],
                backgroundImage: isMe && pickedLocalImage != null ? MemoryImage(pickedLocalImage!) as ImageProvider : _getProfileImage(imageUrl),
                child: (imageUrl == null || imageUrl.isEmpty) && child == null ? const Icon(Icons.person) : child,
              ),
            ),
          ),
        ),
        // UI: Red badge showing number of unread messages from that specific user
        if (badgeCount > 0)
          Positioned(
            right: 0, top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white, width: 2)),
              child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }
}