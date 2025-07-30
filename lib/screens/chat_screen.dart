import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resq_track4/openai_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final OpenAIService _openAIService = OpenAIService();
  bool _isLoading = false;

  String? _chatId;
  Stream<QuerySnapshot>? _messagesStream;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  void _initChat() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final querySnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .where('userId', isEqualTo: user.uid)
        .where('recipientType', isEqualTo: 'AI')
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      setState(() {
        _chatId = querySnapshot.docs.first.id;
        _messagesStream = FirebaseFirestore.instance
            .collection('chats')
            .doc(_chatId)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .snapshots();
      });
    }
  }

  Future<void> _sendMessage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (_controller.text.trim().isEmpty || user == null) return;

    final userMessageContent = _controller.text.trim();
    _controller.clear();
    setState(() => _isLoading = true);

    try {
      if (_chatId == null) {
        final newChatDoc =
            await FirebaseFirestore.instance.collection('chats').add({
          'userId': user.uid,
          'recipientType': 'AI',
          'startTime': Timestamp.now(),
          'lastMessage': userMessageContent,
        });
        setState(() {
          _chatId = newChatDoc.id;
          _messagesStream = FirebaseFirestore.instance
              .collection('chats')
              .doc(_chatId)
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .snapshots();
        });
      }

      final userMessage = {
        'senderType': 'individual',
        'content': userMessageContent,
        'timestamp': Timestamp.now(),
      };
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .add(userMessage);

      final messagesHistorySnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .orderBy('timestamp')
          .get();
      final historyForAI = messagesHistorySnapshot.docs.map((doc) {
        return {
          "role": doc['senderType'] == 'ai' ? 'assistant' : 'user',
          "content": doc['content']
        };
      }).toList();

      final aiReplyContent = await _openAIService.sendMessage(historyForAI);

      final aiMessage = {
        'senderType': 'ai',
        'content': aiReplyContent,
        'timestamp': Timestamp.now(),
      };
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .add(aiMessage);

      await FirebaseFirestore.instance.collection('chats').doc(_chatId).update({
        'lastMessage': aiReplyContent,
        'lastMessageTime': Timestamp.now(),
      });
    } catch (e) {
      final errorMessage = {
        'senderType': 'ai',
        'content': "Sorry, I couldn't process your request. Error: $e",
        'timestamp': Timestamp.now(),
      };
      if (_chatId != null) {
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(_chatId)
            .collection('messages')
            .add(errorMessage);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0A2342);

    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Assistant"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messagesStream == null
                ? _buildEmptyState()
                : StreamBuilder<QuerySnapshot>(
                    stream: _messagesStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          snapshot.data == null) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _buildEmptyState();
                      }

                      final messages = snapshot.data!.docs;

                      return ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        reverse: true, // Shows latest messages at the bottom
                        itemCount: messages.length + (_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (_isLoading && index == 0) {
                            return const ChatMessage(
                                text: '...', isUser: false, isTyping: true);
                          }
                          final messageDoc =
                              messages[_isLoading ? index - 1 : index];
                          final data =
                              messageDoc.data() as Map<String, dynamic>;
                          return ChatMessage(
                            text: data['content'],
                            isUser: data['senderType'] != 'ai',
                          );
                        },
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, -1))
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Type your question...",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                          borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8.0),
                InkWell(
                  onTap: _isLoading ? null : _sendMessage,
                  borderRadius: BorderRadius.circular(24.0),
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: const BoxDecoration(
                        color: primaryColor, shape: BoxShape.circle),
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.smart_toy_outlined,
                size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text("Ask me anything about emergency situations",
                style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF0A2342),
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
                "I can help with first aid, emergency protocols, and finding resources.",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isTyping;

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
    this.isTyping = false,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0A2342);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              margin: const EdgeInsets.only(right: 8.0),
              child: const CircleAvatar(
                  backgroundColor: primaryColor,
                  child: Icon(Icons.smart_toy_outlined,
                      color: Colors.white, size: 20)),
            ),
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: isUser
                    ? primaryColor.withOpacity(0.1)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isUser
                      ? const Radius.circular(18)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(18),
                ),
              ),
              child: isTyping
                  ? const SizedBox(width: 40, child: Text("..."))
                  : Text(text, style: const TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
