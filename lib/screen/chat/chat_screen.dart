import 'dart:async';

import 'package:chewata/screen/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chewata/controller/chat_controller.dart';
import 'package:chewata/models/message_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:chewata/screen/chat/chat_list_screen.dart';

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

  // Add to _ChatScreenState class
  Timer? _seenCheckTimer;

  @override
  void initState() {
    super.initState();
    _chatController.loadChatMessages(widget.chatId);

    // Set up a timer to periodically mark messages as read
    _seenCheckTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (_chatController.selectedChatId.value == widget.chatId) {
        _chatController.markCurrentChatMessagesAsRead();
      }
    });
  }

  @override
  void dispose() {
    _seenCheckTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Add to _ChatScreenState class
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Mark messages as read whenever this screen is in focus
    if (_chatController.selectedChatId.value == widget.chatId) {
      _chatController.loadChatMessages(widget.chatId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            final ChatController chatController = Get.find<ChatController>();
            chatController.searchedUser.value = null;
            chatController.clearSelectedChat();
            Get.back();
          },
        ),
        title: Obx(() {
          final chat = _chatController.userChats.firstWhere(
            (c) => c.id == widget.chatId,
            orElse: () => null as dynamic,
          );
          if (chat == null) {
            return const Text('Chat Not Found');
          }

          final otherUserId = chat.participants.firstWhere(
            (id) => id != _chatController.currentUser?.id,
            orElse: () => '',
          );

          return Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).primaryColor,
                backgroundImage:
                    _chatController.getChatProfilePic(chat) != null
                        ? NetworkImage(_chatController.getChatProfilePic(chat)!)
                        : null,
                child:
                    _chatController.getChatProfilePic(chat) == null
                        ? Text(
                          _chatController.getChatName(chat)[0].toUpperCase(),
                          style: TextStyle(color: Colors.white),
                        )
                        : null,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _chatController.getChatName(chat),
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (otherUserId.isNotEmpty)
                      Obx(() {
                        final isOnline =
                            _chatController.userOnlineStatus[otherUserId] ??
                            false;
                        final lastSeen =
                            _chatController.userLastSeen[otherUserId];

                        return Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isOnline ? Colors.green : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              isOnline
                                  ? 'Online'
                                  : lastSeen != null
                                  ? formatLastSeen(lastSeen)
                                  : 'Offline',
                              style: GoogleFonts.ubuntu(
                                fontSize: 12,
                                color:
                                    isOnline
                                        ? Colors.green[300]
                                        : Colors.grey[600],
                              ),
                            ),
                          ],
                        );
                      }),
                  ],
                ),
              ),
            ],
          );
        }),
        actions: [
          // Add more actions here if needed
          PopupMenuButton(
            itemBuilder:
                (context) => [
                  PopupMenuItem(child: Text('View Profile'), value: 'profile'),
                  PopupMenuItem(child: Text('Clear Chat'), value: 'clear'),
                ],
            onSelected: (value) {
              if (value == 'profile') {
                // Handle view profile
              } else if (value == 'clear') {
                // Handle clear chat
              }
            },
          ),
        ],
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
                        style: GoogleFonts.ubuntu(
                          fontSize: 16,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start the conversation by sending a message',
                        style: GoogleFonts.ubuntu(
                          fontSize: 14,
                          color:
                              isDarkMode ? Colors.grey[500] : Colors.grey[700],
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
                      fillColor:
                          isDarkMode ? Colors.grey[800] : Colors.grey[200],
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

  // In chat_screen.dart, modify the _buildMessageBubble method:
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
              constraints: BoxConstraints(
                maxWidth:
                    MediaQuery.of(context).size.width * 0.75, // Limit max width
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              decoration: BoxDecoration(
                color:
                    isCurrentUser
                        ? Theme.of(context).primaryColor.withOpacity(0.9)
                        : isDarkMode
                        ? Colors.black
                        : Colors.grey[300],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft:
                      isCurrentUser
                          ? const Radius.circular(16)
                          : const Radius.circular(0),
                  bottomRight:
                      isCurrentUser
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
                    style: GoogleFonts.ubuntu(
                      color:
                          isCurrentUser
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
                      // Display message time
                      Text(
                        DateFormat.Hm().format(message.sentAt),
                        style: GoogleFonts.ubuntu(
                          fontSize: 11,
                          color:
                              isCurrentUser
                                  ? Colors.white.withOpacity(0.7)
                                  : isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[700],
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 4),
                        // Show appropriate checkmark based on message status
                        Icon(
                          message.isRead
                              ? Icons
                                  .done_all // Double checkmark for "seen"
                              : Icons.done, // Single checkmark for "delivered"
                          size: 14,
                          color:
                              message.isRead
                                  ? Colors
                                      .blue // Blue for "seen"
                                  : Colors.white.withOpacity(
                                    0.7,
                                  ), // Grey for "delivered"
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

  // Add this helper method to format last seen time
  String formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'Offline';

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM d').format(lastSeen);
    }
  }
}
