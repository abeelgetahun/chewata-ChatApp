import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chewata/models/user_model.dart';
import 'package:chewata/models/message_model.dart';
import 'package:chewata/services/auth_service.dart';
import 'package:intl/intl.dart';

class RandomChatScreen extends StatefulWidget {
  final String chatId;
  final UserModel partner;

  const RandomChatScreen({
    Key? key,
    required this.chatId,
    required this.partner,
  }) : super(key: key);

  @override
  _RandomChatScreenState createState() => _RandomChatScreenState();
}

class _RandomChatScreenState extends State<RandomChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = Get.find<AuthService>();
  final ScrollController _scrollController = ScrollController();
  
  late Stream<QuerySnapshot> _messagesStream;
  bool _isChatActive = true;
  
  @override
  void initState() {
    super.initState();
    _messagesStream = _firestore
        .collection('messages')
        .where('chatId', isEqualTo: widget.chatId)
        .orderBy('sentAt', descending: true)
        .snapshots();
    
    // Check if chat is still active
    _checkChatStatus();
  }
  
  Future<void> _checkChatStatus() async {
    final chatDoc = await _firestore.collection('chats').doc(widget.chatId).get();
    if (chatDoc.exists) {
      final data = chatDoc.data();
      if (data != null && 
          data['metadata'] != null && 
          data['metadata']['isActive'] != null) {
        setState(() {
          _isChatActive = data['metadata']['isActive'];
        });
      }
    }
    
    // Listen for changes to chat status
    _firestore.collection('chats').doc(widget.chatId).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && 
            data['metadata'] != null && 
            data['metadata']['isActive'] != null) {
          setState(() {
            _isChatActive = data['metadata']['isActive'];
          });
        }
      }
    });
  }
  
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || !_isChatActive) return;
    
    // ...existing code...
final currentUserId = _authService.firebaseUser.value?.uid;
// ...existing code...
    if (currentUserId == null) return;
    
    try {
      final messageRef = _firestore.collection('messages').doc();
      final newMessage = MessageModel(
        id: messageRef.id,
        chatId: widget.chatId,
        senderId: currentUserId,
        text: _messageController.text.trim(),
        sentAt: DateTime.now(),
        isRead: false,
        isDelivered: false,
      );
      
      await messageRef.set(newMessage.toMap());
      
      // Update the chat with last message info
      await _firestore.collection('chats').doc(widget.chatId).update({
        'lastMessageText': _messageController.text.trim(),
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUserId,
        'unreadCount.${widget.partner.id}': FieldValue.increment(1),
      });
      
      _messageController.clear();
      
    } catch (e) {
      print('Error sending message: $e');
      Get.snackbar(
        'Error',
        'Failed to send message. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  Future<void> _endChat() async {
    try {
      // Update the chat metadata to mark it as inactive
      await _firestore.collection('chats').doc(widget.chatId).update({
        'metadata.isActive': false,
        'metadata.endedAt': FieldValue.serverTimestamp(),
      });
      
      // Send a system message indicating the chat has ended
      final messageRef = _firestore.collection('messages').doc();
      final systemMessage = MessageModel(
        id: messageRef.id,
        chatId: widget.chatId,
        senderId: 'system',
        text: 'This chat has ended.',
        sentAt: DateTime.now(),
        isRead: false,
        isDelivered: true,
        metadata: {'isSystemMessage': true},
      );
      
      await messageRef.set(systemMessage.toMap());
      
      // Navigate back
      Get.back();
      
    } catch (e) {
      print('Error ending chat: $e');
      Get.snackbar(
        'Error',
        'Failed to end chat. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  void _showEndChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Chat'),
        content: const Text(
          'Are you sure you want to end this chat? This action cannot be undone, and the chat history will be cleared.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _endChat();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('End Chat'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // ...existing code...
final currentUserId = _authService.firebaseUser.value?.uid;
// ...existing code...
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Random Chat'),
            Text(
              'with ${widget.partner.fullName}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          if (_isChatActive)
            IconButton(
              onPressed: _showEndChatDialog,
              icon: const Icon(Icons.close),
              tooltip: 'End Chat',
            ),
        ],
      ),
      body: Column(
        children: [
          // Chat not active banner
          if (!_isChatActive)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.red,
              width: double.infinity,
              child: const Text(
                'This chat has ended',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
          // Messages list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/start_chat.svg',
                          height: 100,
                          width: 100,
                          colorFilter: ColorFilter.mode(
                            isDarkMode ? Colors.white70 : Colors.black54,
                            BlendMode.srcIn,
                          ),
                          placeholderBuilder: (context) => Icon(
                            Icons.chat_bubble_outline,
                            size: 100,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Send a message to start the conversation!',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                
                // Mark messages as read
                _markMessagesAsRead(snapshot.data!.docs, currentUserId);
                
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(8),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final message = MessageModel.fromMap(data, doc.id);
                    
                    // Check if it's a system message
                    final isSystemMessage = 
                        message.metadata != null && 
                        message.metadata!['isSystemMessage'] == true;
                    
                    if (isSystemMessage) {
                      return _buildSystemMessage(message);
                    }
                    
                    final isCurrentUser = message.senderId == currentUserId;
                    
                    return _buildMessageBubble(
                      message: message,
                      isCurrentUser: isCurrentUser,
                      isDarkMode: isDarkMode,
                    );
                  },
                );
              },
            ),
          ),
          
          // Message input
          _buildMessageInput(isDarkMode),
        ],
      ),
    );
  }
  
  Widget _buildSystemMessage(MessageModel message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[700],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.text,
          style: const TextStyle(
            color: Colors.white,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
  
  Widget _buildMessageBubble({
    required MessageModel message,
    required bool isCurrentUser,
    required bool isDarkMode,
  }) {
    final time = DateFormat.Hm().format(message.sentAt);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? Theme.of(context).primaryColor
              : isDarkMode
                  ? Colors.grey[800]
                  : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isCurrentUser
                    ? Colors.white
                    : isDarkMode
                        ? Colors.white
                        : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: isCurrentUser
                        ? Colors.white70
                        : isDarkMode
                            ? Colors.white70
                            : Colors.black54,
                  ),
                ),
                if (isCurrentUser) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead
                        ? Icons.done_all
                        : message.isDelivered
                            ? Icons.done
                            : Icons.access_time,
                    size: 14,
                    color: message.isRead ? Colors.blue : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMessageInput(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: _isChatActive,
              decoration: InputDecoration(
                hintText: _isChatActive 
                    ? 'Type a message...' 
                    : 'Chat has ended',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              ),
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: _isChatActive ? _sendMessage : null,
            mini: true,
            backgroundColor: _isChatActive 
                ? Theme.of(context).primaryColor 
                : Colors.grey,
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
  
  void _markMessagesAsRead(List<QueryDocumentSnapshot> docs, String? currentUserId) {
    if (currentUserId == null) return;
    
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['senderId'] != currentUserId && data['isRead'] == false) {
        // Mark message as read
        _firestore.collection('messages').doc(doc.id).update({
          'isRead': true,
        });
        
        // Update unread count in chat
        _firestore.collection('chats').doc(widget.chatId).update({
          'unreadCount.$currentUserId': 0,
        });
      }
    }
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}