import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chewata/controller/chat_controller.dart';
import 'package:chewata/models/chat_model.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ChatController>()) {
      Get.put(ChatController());
    }
    final ChatController chatController = Get.find<ChatController>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isDarkMode
                  ? [Colors.black, Colors.black]
                  : [Colors.white, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
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
                      user.fullName.isNotEmpty
                          ? user.fullName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(user.fullName),
                  subtitle: Text(user.email),
                  trailing: ElevatedButton(
                    onPressed: () {
                      chatController.createOrGetChatWithUser(user.id);
                    },
                    child: Obx(
                      () =>
                          chatController.isLoading.value
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Chat'),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),

            Expanded(
              child: Obx(() {
                if (chatController.isInitialLoading.value) {
                  return _buildShimmerLoading(context);
                }

                if (chatController.userChats.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color:
                              isDarkMode ? Colors.grey[600] : Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No chats yet',
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Search for a user to start chatting',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                isDarkMode
                                    ? Colors.grey[500]
                                    : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (scrollInfo is ScrollEndNotification &&
                        scrollInfo.metrics.extentAfter < 500) {
                      chatController.loadMoreChats();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    physics: BouncingScrollPhysics(),
                    itemCount:
                        chatController.userChats.length +
                        (chatController.hasMoreChats.value ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= chatController.userChats.length) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final chat = chatController.userChats[index];

                      // AnimatedSwitcher + Slide + Fade
                      return AnimatedSwitcher(
                        duration: Duration(milliseconds: 500),
                        transitionBuilder: (child, animation) {
                          final offsetAnimation = Tween<Offset>(
                            begin: Offset(1, 0),
                            end: Offset(0, 0),
                          ).animate(animation);
                          return SlideTransition(
                            position: offsetAnimation,
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: _buildChatTile(
                          context,
                          chat,
                          chatController,
                          index.toString(),
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.builder(
        itemCount: 8,
        itemBuilder:
            (_, __) => Container(
              margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                ),
                title: Container(
                  width: double.infinity,
                  height: 18,
                  color: Colors.white,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      height: 14,
                      color: Colors.white,
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(width: 40, height: 12, color: Colors.white),
                    SizedBox(height: 4),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildChatTile(
    BuildContext context,
    ChatModel chat,
    ChatController chatController,
    String uniqueKey,
  ) {
    final chatName = chatController.getChatName(chat);
    final unreadCount = chatController.getUnreadCount(chat);
    final lastMessageTime = chat.lastMessageTime;
    final profilePic = chatController.getChatProfilePic(chat);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final otherUserId = chat.participants.firstWhere(
      (id) => id != chatController.currentUser?.id,
      orElse: () => '',
    );

    return Container(
      key: ValueKey(uniqueKey),
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.grey.shade50,
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
              backgroundImage:
                  profilePic != null && profilePic.isNotEmpty
                      ? NetworkImage(profilePic)
                      : null,
              child:
                  profilePic == null || profilePic.isEmpty
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
            Positioned(
              right: 0,
              bottom: 0,
              child: Obx(() {
                final isOnline =
                    chatController.userOnlineStatus[otherUserId] ?? false;
                return Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color:
                        isOnline
                            ? Colors.green
                            : (isDarkMode
                                ? Colors.grey[700]
                                : Colors.grey[400]),
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
                  fontWeight:
                      unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                  color:
                      unreadCount > 0
                          ? (isDarkMode ? Colors.white : Colors.black87)
                          : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                ),
              )
            else
              const Text('No messages yet'),
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

  String _formatChatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return DateFormat.Hm().format(time);
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(time).inDays < 7) {
      return DateFormat.E().format(time);
    } else {
      return DateFormat.MMMd().format(time);
    }
  }
}
