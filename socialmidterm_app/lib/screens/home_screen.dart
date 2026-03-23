import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:socialmidterm_app/main.dart';
import 'create_post_screen.dart';
import '/widgets/feed_page.dart';
import '/widgets/sidebar_users.dart';
import 'create_story_screen.dart';
import 'story_view_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'chat_screen.dart';
import 'ai_chat_screen.dart';
import 'user_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  final String? profileImage;

  HomeScreen({required this.username, this.profileImage});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0; // Logic: Controls which page is displayed (Feed, Messages, or Profile)
  final TextEditingController _searchController = TextEditingController(); // Logic: Manages the global search input
  String _searchQuery = ""; // Logic: Stores the current search text to filter the user list

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final myApp = MyApp.of(context);

    // 1. Connection: Listens for changes to the CURRENT user's profile (name/image updates)
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, userSnapshot) {

        // Logic: Instead of showing the logo asset every time the stream connects,
        // we show a standard centered loader to keep the UI clean during reloads.
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: const Center(
              child: CircularProgressIndicator(), // UI: Simple spinner
            ),
          );
        }
        // --- END OF LOGO REMOVAL ---

        String livePic = widget.profileImage ?? '';
        String liveName = widget.username;

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          var data = userSnapshot.data!.data() as Map<String, dynamic>;
          livePic = data['profileImage'] ?? livePic;
          liveName = data['username'] ?? liveName;
        }

        // 2. Connection: Listens for all active stories from all users
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('storiess').snapshots(),
          builder: (context, storySnapshot) {
            Map<String, Map<String, String>> activeStoriesData = {};
            if (storySnapshot.hasData) {
              final now = DateTime.now();
              for (var doc in storySnapshot.data!.docs) {
                var data = doc.data() as Map<String, dynamic>;
                Timestamp? expires = data['expiresAt'];
                // Logic: Only shows stories that haven't reached their 24-hour expiration yet
                if (expires != null && expires.toDate().isAfter(now)) {
                  activeStoriesData[data['uid']] = {
                    'url': data['imageUrl'] ?? '',
                    'type': data['type'] ?? 'image',
                  };
                }
              }
            }

            // 3. Connection: Listens for the list of all registered users
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, allUsersSnapshot) {
                // 4. Connection: Listens specifically for unread messages sent to the current user
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .where('receiverId', isEqualTo: uid)
                      .where('isRead', isEqualTo: false)
                      .snapshots(),
                  builder: (context, chatSnapshot) {
                    List<DocumentSnapshot> allOtherUsers = [];
                    Map<String, int> unreadMap = {};

                    if (allUsersSnapshot.hasData) {
                      // Logic: Filters out the current user from the contact list
                      allOtherUsers = allUsersSnapshot.data!.docs.where((doc) => doc.id != uid).toList();
                      if (chatSnapshot.hasData) {
                        for (var doc in chatSnapshot.data!.docs) {
                          String senderId = doc['senderId'] ?? '';
                          // Logic: Maps sender IDs to their specific unread message counts
                          unreadMap[senderId] = (unreadMap[senderId] ?? 0) + 1;
                        }
                      }
                    }

                    // UI: The three main views accessible via the Drawer or Sidebar
                    final pages = [
                      const FeedPage(),
                      _buildChatListPage(allOtherUsers, unreadMap),
                      ProfileScreen(username: liveName, profileImage: livePic),
                    ];

                    // Logic: Filters the user list in real-time based on the top search bar
                    List<DocumentSnapshot> searchResults = allOtherUsers.where((u) {
                      final name = (u.data() as Map<String, dynamic>)['username']?.toString().toLowerCase() ?? '';
                      return name.contains(_searchQuery.toLowerCase());
                    }).toList();

                    return Scaffold(
                      appBar: AppBar(
                        title: const Text("JoshquadApp", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        actions: [
                          // UI: Quick access to the Gemini AI Assistant
                          IconButton(
                            icon: const Icon(Icons.auto_awesome, color: Colors.amber),
                            tooltip: "AI Assistant",
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const AiChatScreen()));
                            },
                          ),
                          // UI: Styled Search bar inside the AppBar
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Container(
                              width: 150,
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (val) => setState(() => _searchQuery = val),
                                textAlignVertical: TextAlignVertical.center,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: "Search...",
                                  prefixIcon: const Icon(Icons.search, size: 16),
                                  isDense: true,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                    icon: const Icon(Icons.close, size: 14),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = "");
                                    },
                                  )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          // UI: Quick theme toggle (Sun/Moon icon)
                          IconButton(
                            icon: Icon(myApp?.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
                            onPressed: () => myApp?.toggleTheme(myApp.themeMode == ThemeMode.light),
                          ),
                        ],
                      ),
                      drawer: _buildDrawer(context, liveName, livePic, unreadMap.length),
                      body: Row(
                        children: [
                          // UI: The left-side vertical bar showing stories and online friends
                          SidebarUsers(
                            myProfile: livePic,
                            otherUsers: allOtherUsers,
                            activeStoriesByUid: activeStoriesData.map((key, value) => MapEntry(key, value['url']!)),
                            unreadCounts: unreadMap,
                            onMyProfileTap: () => setState(() => index = 2),
                            onAddStoryTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateStoryScreen())),
                            onFriendTap: (clickedUid) {
                              // Logic: If user has a story, view it; otherwise, visit their profile
                              if (activeStoriesData.containsKey(clickedUid)) {
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => StoryViewScreen(
                                    url: activeStoriesData[clickedUid]!['url']!,
                                    type: activeStoriesData[clickedUid]!['type']!,
                                  ),
                                ));
                              } else {
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => UserProfileScreen(userId: clickedUid),
                                ));
                              }
                            },
                          ),
                          Expanded(
                            child: Stack(
                              children: [
                                pages[index], // UI: Displays Feed, ChatList, or Profile
                                // UI: Overlay for search results when the user is typing
                                if (_searchQuery.isNotEmpty)
                                  Container(
                                    color: Theme.of(context).scaffoldBackgroundColor,
                                    child: ListView.builder(
                                      itemCount: searchResults.length,
                                      itemBuilder: (context, i) {
                                        var data = searchResults[i].data() as Map<String, dynamic>;
                                        String targetId = searchResults[i].id;
                                        return ListTile(
                                          leading: CircleAvatar(
                                            backgroundImage: (data['profileImage'] != null && data['profileImage'].isNotEmpty)
                                                ? NetworkImage(data['profileImage'])
                                                : null,
                                            child: (data['profileImage'] == null || data['profileImage'].isEmpty) ? const Icon(Icons.person) : null,
                                          ),
                                          title: Text(data['username'] ?? 'User'),
                                          onTap: () {
                                            _searchController.clear();
                                            setState(() => _searchQuery = "");
                                            Navigator.push(context, MaterialPageRoute(
                                              builder: (_) => UserProfileScreen(userId: targetId),
                                            ));
                                          },
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // UI: Main action button to create a new post
                      floatingActionButton: FloatingActionButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreatePostScreen(username: liveName, profileImage: livePic))),
                        child: const Icon(Icons.add),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // UI: The slide-out menu containing navigation links and Logout
  Widget _buildDrawer(BuildContext context, String name, String pic, int totalUnread) {
    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(FirebaseAuth.instance.currentUser?.email ?? ""),
            currentAccountPicture: CircleAvatar(
              backgroundImage: pic.isNotEmpty ? NetworkImage(pic) : null,
              child: pic.isEmpty ? const Icon(Icons.person) : null,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text("Feed"),
            onTap: () { setState(() => index = 0); Navigator.pop(context); },
          ),
          ListTile(
            leading: const Icon(Icons.message),
            title: const Text("Messages"),
            trailing: totalUnread > 0 ? Badge(label: Text('$totalUnread')) : null,
            onTap: () { setState(() => index = 1); Navigator.pop(context); },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Profile"),
            onTap: () { setState(() => index = 2); Navigator.pop(context); },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Settings"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }

  // UI: The screen content for the "Messages" tab
  Widget _buildChatListPage(List<DocumentSnapshot> otherUsers, Map<String, int> unreadMap) {
    return ListView.builder(
      itemCount: otherUsers.length,
      itemBuilder: (context, index) {
        var user = otherUsers[index].data() as Map<String, dynamic>;
        String userId = otherUsers[index].id;
        int unreadCount = unreadMap[userId] ?? 0;
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: (user['profileImage'] != null && user['profileImage'].isNotEmpty)
                ? NetworkImage(user['profileImage'])
                : null,
            child: (user['profileImage'] == null || user['profileImage'].isEmpty)
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(
              user['username'] ?? 'User',
              style: TextStyle(fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal)
          ),
          trailing: unreadCount > 0 ? Badge(label: Text('$unreadCount')) : null,
          onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ChatScreen(receiverId: userId, receiverName: user['username'] ?? 'User')
          )),
        );
      },
    );
  }
}