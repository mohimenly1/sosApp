import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
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
  File? _imageFile; // To hold the selected image

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

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final fileName = path.basename(image.path);
      final destination = 'chat_images/$_chatId/$fileName';
      final ref = FirebaseStorage.instance.ref(destination);
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      print("Failed to upload image: $e");
      return null;
    }
  }

  Future<void> _sendMessage() async {
    final user = FirebaseAuth.instance.currentUser;
    if ((_controller.text.trim().isEmpty && _imageFile == null) || user == null)
      return;

    final userMessageContent = _controller.text.trim();
    final File? imageToSend = _imageFile;

    _controller.clear();
    setState(() {
      _isLoading = true;
      _imageFile = null;
    });

    try {
      if (_chatId == null) {
        final newChatDoc =
            await FirebaseFirestore.instance.collection('chats').add({
          'userId': user.uid,
          'recipientType': 'AI',
          'startTime': Timestamp.now(),
          'lastMessage':
              userMessageContent.isNotEmpty ? userMessageContent : "Image",
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

      String? imageUrl;
      if (imageToSend != null) {
        imageUrl = await _uploadImage(imageToSend);
      }

      final userMessage = {
        'senderType': 'individual',
        'content': userMessageContent,
        'imageUrl': imageUrl, // Save image URL to Firestore
        'timestamp': Timestamp.now(),
      };
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .add(userMessage);

      // Fetch history and send to AI
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

      final aiReplyContent = await _openAIService.sendMessage(historyForAI,
          imageFile: imageToSend);

      final aiMessage = {
        'senderType': 'ai',
        'content': aiReplyContent,
        'imageUrl': null,
        'timestamp': Timestamp.now(),
      };
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .add(aiMessage);
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId)
          .update({'lastMessage': aiReplyContent});
    } catch (e) {
      // Handle error...
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
          foregroundColor: Colors.white),
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
                        reverse: true,
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
                            imageUrl: data['imageUrl'],
                            isUser: data['senderType'] != 'ai',
                          );
                        },
                      );
                    },
                  ),
          ),
          if (_imageFile != null) // Show a preview of the selected image
            Container(
              padding: const EdgeInsets.all(8),
              child: Row(children: [
                Image.file(_imageFile!,
                    width: 50, height: 50, fit: BoxFit.cover),
                const SizedBox(width: 8),
                const Expanded(child: Text("Image attached")),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _imageFile = null)),
              ]),
            ),
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                    icon: const Icon(Icons.attach_file, color: primaryColor),
                    onPressed: _pickImage),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                        hintText: "Type your question...",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24.0))),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.send, color: primaryColor),
                    onPressed: _isLoading ? null : _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
        child: Text("Ask me anything about emergency situations"));
  }
}

// Chat bubble widget now supports displaying images
class ChatMessage extends StatelessWidget {
  final String text;
  final String? imageUrl;
  final bool isUser;
  final bool isTyping;

  const ChatMessage({
    super.key,
    required this.text,
    this.imageUrl,
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
        children: [
          if (!isUser)
            const CircleAvatar(
                backgroundColor: primaryColor,
                child: Icon(Icons.smart_toy_outlined, color: Colors.white)),
          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: isUser
                    ? primaryColor.withOpacity(0.1)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageUrl != null)
                    ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(imageUrl!)),
                  if (text.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: imageUrl != null ? 8.0 : 0),
                      child: Text(text, style: const TextStyle(fontSize: 16)),
                    ),
                  if (isTyping) const Text("..."),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
