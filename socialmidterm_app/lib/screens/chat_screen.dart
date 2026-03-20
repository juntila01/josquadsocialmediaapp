import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Connection: Essential for real-time message streaming
import 'package:firebase_auth/firebase_auth.dart'; // Connection: Used to identify the sender of the message

class ChatScreen extends StatefulWidget {
  // Logic: Requires the ID and Name of the person you are talking to
  final String receiverId;
  final String receiverName;

  const ChatScreen({Key? key, required this.receiverId, required this.receiverName}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Logic: Controller to manage the text typed in the message bar
  final TextEditingController _messageController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // Connection: This function clears the red badges in your sidebar
  // Logic: Finds all unread messages where YOU are the receiver and updates them to 'isRead: true'
  void _markAsRead() async {
    var query = await FirebaseFirestore.instance
        .collection('chats')
        .where('senderId', isEqualTo: widget.receiverId)
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in query.docs) {
      doc.reference.update({'isRead': true});
    }
  }

  // Logic: Function to upload a new message document to Firestore
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    await FirebaseFirestore.instance.collection('chats').add({
      'senderId': currentUserId,
      'receiverId': widget.receiverId,
      'text': _messageController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(), // Logic: Critical for sorting the conversation chronologically
      'isRead': false, // Connection: Crucial for your Sidebar notification badges
    });

    // UI: Resets the input field after the message is sent
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    // Logic: Automatically marks messages as read whenever the chat window is active
    _markAsRead();

    return Scaffold(
      appBar: AppBar(
        // UI: Custom back button to ensure visibility on the primary theme color
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        // Connection: Real-time listener for the receiver's profile info
        // Logic: Ensures the name and picture are always up-to-date in the header
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(widget.receiverId).snapshots(),
          builder: (context, snapshot) {
            String name = widget.receiverName;
            String? profilePic;

            if (snapshot.hasData && snapshot.data!.exists) {
              var data = snapshot.data!.data() as Map<String, dynamic>;
              name = data['username'] ?? name;
              profilePic = data['profileImage'];
            }

            return Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: (profilePic != null && profilePic.isNotEmpty)
                      ? NetworkImage(profilePic)
                      : null,
                  child: (profilePic == null || profilePic.isEmpty)
                      ? const Icon(Icons.person, size: 20)
                      : null,
                ),
                const SizedBox(width: 12),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            // Connection: Listens for EVERY message in the 'chats' collection
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                // Logic: Client-side filter to only show messages between YOU and THIS SPECIFIC receiver
                var chatDocs = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  return (data['senderId'] == currentUserId && data['receiverId'] == widget.receiverId) ||
                      (data['senderId'] == widget.receiverId && data['receiverId'] == currentUserId);
                }).toList();

                return ListView.builder(
                  reverse: true, // UI: Keeps the newest messages at the bottom of the screen
                  padding: const EdgeInsets.all(16),
                  itemCount: chatDocs.length,
                  itemBuilder: (context, index) {
                    var data = chatDocs[index].data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] == currentUserId;

                    // UI: Aligns messages to the Right if sent by you, Left if received
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          // UI: Uses the app's primary color for outgoing messages and dark grey for incoming
                          color: isMe ? Theme.of(context).primaryColor : Colors.grey.shade800,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(14),
                            topRight: const Radius.circular(14),
                            bottomLeft: Radius.circular(isMe ? 14 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 14),
                          ),
                        ),
                        child: Text(
                          data['text'] ?? '',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message Input Field
          // UI: Styled input area with a floating action button for sending
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Message...",
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Logic: Standard resource cleanup
    _messageController.dispose();
    super.dispose();
  }
}