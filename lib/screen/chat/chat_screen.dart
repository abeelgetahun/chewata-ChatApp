import 'dart:async';

import 'package:chewata/models/user_model.dart';
import 'package:chewata/screen/chat/user_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:chewata/controller/chat_controller.dart';
import 'package:chewata/models/message_model.dart';
import 'package:google_fonts/google_fonts.dart';
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

  // Add to _ChatScreenState class
  Timer? _seenCheckTimer;

  // Message editing state
  String? _editingMessageId;

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
          final matches =
              _chatController.userChats
                  .where((c) => c.id == widget.chatId)
                  .toList();
          final chat = matches.isNotEmpty ? matches.first : null;
          if (chat == null) {
            return const Text('Chat Not Found');
          }

          final otherUserId = chat.participants.firstWhere(
            (id) => id != _chatController.currentUser?.id,
            orElse: () => '',
          );

          final titleContent = Row(
            children: [
              _buildAvatar(
                context,
                _chatController.getChatProfilePic(chat),
                _chatController.getChatName(chat),
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

          return GestureDetector(
            onTap: () {
              final UserModel? user = _chatController.getOtherUser(
                widget.chatId,
              );
              if (user != null) {
                Get.to(() => UserProfileScreen(user: user));
              }
            },
            child: titleContent,
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
                final user = _chatController.getOtherUser(widget.chatId);
                if (user != null) {
                  Get.to(() => UserProfileScreen(user: user));
                }
              } else if (value == 'clear') {
                showDialog(
                  context: context,
                  builder:
                      (ctx) => AlertDialog(
                        title: const Text('Clear chat?'),
                        content: const Text(
                          'This will delete your messages in this chat. The other user will still see their messages.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.of(ctx).pop();
                              await _chatController.clearChat(widget.chatId);
                            },
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                );
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
          if (_editingMessageId != null)
            Container(
              color: isDarkMode ? Colors.grey[850] : Colors.blue[50],
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.edit, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Editing message')),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() => _editingMessageId = null);
                      _messageController.clear();
                    },
                  ),
                ],
              ),
            ),
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
                    icon: Icon(
                      _editingMessageId == null ? Icons.send : Icons.check,
                      color: Colors.white,
                    ),
                    onPressed: () async {
                      final text = _messageController.text.trim();
                      if (text.isEmpty) return;

                      if (_editingMessageId == null) {
                        await _chatController.sendMessage(text);
                      } else {
                        await _chatController.editMessage(
                          widget.chatId,
                          _editingMessageId!,
                          text,
                        );
                        setState(() => _editingMessageId = null);
                      }
                      _messageController.clear();
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

  Widget _buildAvatar(
    BuildContext context,
    String? imageUrl,
    String displayName,
  ) {
    String initials = 'U';
    final trimmed = displayName.trim();
    if (trimmed.isNotEmpty) {
      initials = trimmed.characters.first.toUpperCase();
    }

    final bool hasValidUrl =
        imageUrl != null &&
        imageUrl.trim().isNotEmpty &&
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'));

    final fallback = Text(
      initials,
      style: const TextStyle(color: Colors.white),
    );

    if (!hasValidUrl) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: Theme.of(context).primaryColor,
        child: fallback,
      );
    }

    return CircleAvatar(
      radius: 18,
      backgroundColor: Theme.of(context).primaryColor,
      child: ClipOval(
        child: Image.network(
          imageUrl,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, st) => fallback,
        ),
      ),
    );
  }

  // In chat_screen.dart, modify the _buildMessageBubble method:
  Widget _buildMessageBubble(BuildContext context, MessageModel message) {
    final currentUserId = _chatController.currentUser?.id;
    final isCurrentUser = message.senderId == currentUserId;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final bubble = Padding(
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
                    message.isDeleted
                        ? (isDarkMode ? Colors.grey[800] : Colors.grey[200])
                        : isCurrentUser
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
                  if (message.isDeleted)
                    Text(
                      isCurrentUser
                          ? 'You deleted this message'
                          : 'Message deleted',
                      style: GoogleFonts.ubuntu(
                        fontStyle: FontStyle.italic,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      ),
                    )
                  else
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
                      if (message.isEdited && !message.isDeleted) ...[
                        Text(
                          'edited · ',
                          style: GoogleFonts.ubuntu(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color:
                                isCurrentUser
                                    ? Colors.white.withOpacity(0.7)
                                    : isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[700],
                          ),
                        ),
                      ],
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

    return GestureDetector(
      onLongPress: () => _showMessageActions(context, message),
      child: bubble,
    );
  }

  void _showMessageActions(BuildContext context, MessageModel message) {
    final isCurrentUser = message.senderId == _chatController.currentUser?.id;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!message.isDeleted)
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: const Text('Copy'),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: message.text));
                    Navigator.of(ctx).pop();
                  },
                ),
              if (isCurrentUser && !message.isDeleted)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    setState(() {
                      _editingMessageId = message.id;
                      _messageController.text = message.text;
                    });
                  },
                ),
              if (isCurrentUser)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Delete'),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await _chatController.deleteMessage(
                      widget.chatId,
                      message.id,
                    );
                  },
                ),
            ],
          ),
        );
      },
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
