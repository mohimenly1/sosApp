import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class P2PChatScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;

  const P2PChatScreen({
    super.key,
    required this.recipientId,
    required this.recipientName,
  });

  @override
  State<P2PChatScreen> createState() => _P2PChatScreenState();
}

class _P2PChatScreenState extends State<P2PChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  late final String _chatId;
  late final Stream<QuerySnapshot> _messagesStream;

  @override
  void initState() {
    super.initState();
    // Create a unique, consistent chat ID from the two user IDs
    List<String> ids = [_currentUserId, widget.recipientId];
    ids.sort();
    _chatId = ids.join('_');

    _messagesStream = FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final messageContent = _controller.text.trim();
    _controller.clear();

    final messageData = {
      'senderId': _currentUserId,
      'content': messageContent,
      'timestamp': Timestamp.now(),
    };

    // Set the latest message info in the parent chat document
    await FirebaseFirestore.instance.collection('chats').doc(_chatId).set({
      'participants': [_currentUserId, widget.recipientId],
      'lastMessage': messageContent,
      'lastMessageTimestamp': Timestamp.now(),
    }, SetOptions(merge: true));

    // Add the new message to the messages subcollection
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .add(messageData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.recipientName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Start the conversation!'));
                }

                final messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == _currentUserId;
                    return _buildMessageBubble(msg['content'], isMe);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF0A2342) : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: TextStyle(color: isMe ? Colors.white : Colors.black)),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Type a message...",
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.0)),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFF0A2342)),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
