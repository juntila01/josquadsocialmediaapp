import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Connection: Essential for real-time message streaming
import 'package:firebase_auth/firebase_auth.dart'; // Connection: Used to identify the sender of the message
import 'package:socialmidterm_app/screens/user_profile_screen.dart'; // Connection: Updated to match your UserProfileScreen filename

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatScreen({Key? key, required this.receiverId, required this.receiverName}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

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

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    await FirebaseFirestore.instance.collection('chats').add({
      'senderId': currentUserId,
      'receiverId': widget.receiverId,
      'text': _messageController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    _markAsRead();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
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

            return InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserProfileScreen(userId: widget.receiverId)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: (profilePic != null && profilePic.isNotEmpty) ? NetworkImage(profilePic) : null,
                    child: (profilePic == null || profilePic.isEmpty) ? const Icon(Icons.person, size: 20, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 12),
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              // Logic: Fetching the receiver's data once more to show the image next to messages
              stream: FirebaseFirestore.instance.collection('users').doc(widget.receiverId).snapshots(),
              builder: (context, userSnap) {
                String? receiverPic = userSnap.hasData && userSnap.data!.exists
                    ? (userSnap.data!.data() as Map<String, dynamic>)['profileImage']
                    : null;

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('chats').orderBy('timestamp', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                    var chatDocs = snapshot.data!.docs.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      return (data['senderId'] == currentUserId && data['receiverId'] == widget.receiverId) ||
                          (data['senderId'] == widget.receiverId && data['receiverId'] == currentUserId);
                    }).toList();

                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: chatDocs.length,
                      itemBuilder: (context, index) {
                        var data = chatDocs[index].data() as Map<String, dynamic>;
                        bool isMe = data['senderId'] == currentUserId;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // UI: Show receiver's profile picture ONLY for their messages
                              if (!isMe) ...[
                                CircleAvatar(
                                  radius: 14,
                                  backgroundImage: (receiverPic != null && receiverPic.isNotEmpty) ? NetworkImage(receiverPic) : null,
                                  child: (receiverPic == null || receiverPic.isEmpty) ? const Icon(Icons.person, size: 15) : null,
                                ),
                                const SizedBox(width: 8),
                              ],

                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
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
                              ),

                              // UI: Small spacer to keep your own messages aligned correctly
                              if (isMe) const SizedBox(width: 30),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

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
    _messageController.dispose();
    super.dispose();
  }
}