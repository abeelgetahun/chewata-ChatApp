import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chewata/controller/chat_controller.dart';
import 'package:chewata/models/chat_model.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize the chat controller if not already done
    if (!Get.isRegistered<ChatController>()) {
      Get.put(ChatController());
    }
    final ChatController chatController = Get.find<ChatController>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [Colors.black, Colors.black]
              : [Colors.white, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // Make Scaffold background transparent
        body: Column(
          children: [
            
            // Search results
            Obx(() {
              if (chatController.isSearching.value) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (chatController.searchedUser.value != null) {
                final user = chatController.searchedUser.value!;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(user.fullName),
                  subtitle: Text(user.email),
                  trailing: ElevatedButton(
                    onPressed: () {
                      chatController.createOrGetChatWithUser(user.id);
                    },
                    child: Obx(() => chatController.isLoading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Chat')),
                  ),
                );
              }
              
              return const SizedBox.shrink();
            }),
            
            // Chat list
            Expanded(
              child: Obx(() {
                if (chatController.userChats.isEmpty) {
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
                          'No chats yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Search for a user to start chatting',
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
                  itemCount: chatController.userChats.length,
                  itemBuilder: (context, index) {
                    final chat = chatController.userChats[index];
                    return _buildChatTile(context, chat, chatController);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
  
  
  // In chat_list_screen.dart, enhance the _buildChatTile method:
  Widget _buildChatTile(
    BuildContext context, 
    ChatModel chat, 
    ChatController chatController
  ) {
    final chatName = chatController.getChatName(chat);
    final unreadCount = chatController.getUnreadCount(chat);
    final lastMessageTime = chat.lastMessageTime;
    final profilePic = chatController.getChatProfilePic(chat);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Get the other user's ID to check online status
    final otherUserId = chat.participants.firstWhere(
      (id) => id != chatController.currentUser?.id,
      orElse: () => '',
    );
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: isDarkMode 
          ? Colors.grey[900] 
          : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Theme.of(context).primaryColor,
              backgroundImage: profilePic != null && profilePic.isNotEmpty
                  ? NetworkImage(profilePic)
                  : null,
              child: profilePic == null || profilePic.isEmpty
                  ? Text(
                      chatName.isNotEmpty ? chatName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            // Enhanced online status indicator
            Positioned(
              right: 0,
              bottom: 0,
              child: Obx(() {
                final isOnline = chatController.userOnlineStatus[otherUserId] ?? false;
                return Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isOnline 
                      ? Colors.green 
                      : (isDarkMode ? Colors.grey[700] : Colors.grey[400]),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDarkMode ? Colors.black : Colors.white,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
        title: Text(
          chatName,
          style: TextStyle(
            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (chat.lastMessageText != null)
              Text(
                chat.lastMessageText!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                  color: unreadCount > 0
                      ? isDarkMode ? Colors.white : Colors.black87
                      : isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              )
            else
              const Text('No messages yet'),
            
            // Add last seen status under the message text
            SizedBox(height: 4),
            Obx(() {
              final isOnline = chatController.userOnlineStatus[otherUserId] ?? false;
              final lastSeen = chatController.userLastSeen[otherUserId];
              
              return Text(
                isOnline 
                  ? '● Online'
                  : lastSeen != null 
                    ? 'Last seen ${_formatLastSeen(lastSeen)}'
                    : 'Offline',
                style: TextStyle(
                  fontSize: 12,
                  color: isOnline
                    ? Colors.green
                    : isDarkMode ? Colors.grey[500] : Colors.grey[600],
                ),
              );
            }),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (lastMessageTime != null)
              Text(
                _formatChatTime(lastMessageTime),
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            const SizedBox(height: 4),
            if (unreadCount > 0)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          chatController.loadChatMessages(chat.id);
          Get.toNamed('/chat/${chat.id}');
        },
      ),
    );
  }

  // Add this helper method to format last seen time
  String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'Offline';
    
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM d').format(lastSeen);
    }
  } 
  String _formatChatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(time.year, time.month, time.day);
    
    if (messageDate == today) {
      return DateFormat.Hm().format(time); // Hours:minutes
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(time).inDays < 7) {
      return DateFormat.E().format(time); // Day of week
    } else {
      return DateFormat.MMMd().format(time); // Jan 1
    }
  }
}