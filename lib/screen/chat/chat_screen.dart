// lib/screen/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chewata/controller/chat_controller.dart';
import 'package:chewata/models/message_model.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  
  const ChatScreen({Key? key, required this.chatId}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatController _chatController = Get.find<ChatController>();
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _chatController.loadChatMessages(widget.chatId);
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            Get.back();
          },
        ),
        title: Obx(() {
          final chat = _chatController.userChats
              .firstWhere((c) => c.id == widget.chatId, orElse: () => null as dynamic);
          if (chat == null) return const Text('Chat');
          return Text(_chatController.getChatName(chat));
        }),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Obx(() {
              if (_chatController.isLoadingMessages.value) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (_chatController.currentChatMessages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No messages yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start the conversation by sending a message',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.grey[500] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                controller: _scrollController,
                reverse: true, // Display messages from bottom
                padding: const EdgeInsets.all(16),
                itemCount: _chatController.currentChatMessages.length,
                itemBuilder: (context, index) {
                  final message = _chatController.currentChatMessages[index];
                  return _buildMessageBubble(context, message);
                },
              );
            }),
          ),
          
          // Message input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[900] : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                // Expanded text field
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    minLines: 1,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                
                // Send button
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      if (_messageController.text.trim().isNotEmpty) {
                        _chatController.sendMessage(_messageController.text);
                        _messageController.clear();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessageBubble(BuildContext context, MessageModel message) {
    final currentUserId = _chatController.currentUser?.id;
    final isCurrentUser = message.senderId == currentUserId;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser) const SizedBox(width: 8),
          
          // Message bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? Theme.of(context).primaryColor
                    : isDarkMode 
                        ? Colors.grey[800]
                        : Colors.grey[300],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isCurrentUser
                      ? const Radius.circular(16)
                      : const Radius.circular(0),
                  bottomRight: isCurrentUser
                      ? const Radius.circular(0)
                      : const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message text
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isCurrentUser
                          ? Colors.white
                          : isDarkMode 
                              ? Colors.white
                              : Colors.black,
                    ),
                  ),
                  
                  // Time and read status
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat.Hm().format(message.sentAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: isCurrentUser
                              ? Colors.white.withOpacity(0.7)
                              : isDarkMode 
                                  ? Colors.grey[400]
                                  : Colors.grey[700],
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: message.isRead
                              ? Colors.white.withOpacity(0.7)
                              : Colors.white.withOpacity(0.4),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          if (isCurrentUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}