import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../chat/p2p_chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to see your chats.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Conversations')),
      body: StreamBuilder<QuerySnapshot>(
        // 1. Fetch all chats where the current user is a participant
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: _currentUserId)
            .orderBy('lastMessageTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No conversations yet.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final chats = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              // Use a helper widget to build each chat list item
              return _ChatListItem(chatDoc: chats[index]);
            },
          );
        },
      ),
    );
  }
}

// Helper widget to build each item in the chat list
class _ChatListItem extends StatelessWidget {
  final DocumentSnapshot chatDoc;
  const _ChatListItem({required this.chatDoc});

  @override
  Widget build(BuildContext context) {
    final chatData = chatDoc.data() as Map<String, dynamic>;
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    // 2. Find the ID of the other user in the conversation
    final participants = List<String>.from(chatData['participants']);
    final otherUserId =
        participants.firstWhere((id) => id != currentUserId, orElse: () => '');

    if (otherUserId.isEmpty) {
      return const SizedBox.shrink(); // Don't show chat if something is wrong
    }

    // 3. Fetch the other user's details to display their name
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          // Show a placeholder while loading user data
          return const ListTile(title: Text("Loading chat..."));
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
        final recipientName = userData?['name'] ?? 'Unknown User';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(recipientName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            // 4. Display the last message
            subtitle: Text(
              chatData['lastMessage'] ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              // 5. Navigate to the P2P chat screen with the correct user info
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => P2PChatScreen(
                    recipientId: otherUserId,
                    recipientName: recipientName,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
