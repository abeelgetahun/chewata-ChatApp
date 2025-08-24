import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chewata/controller/auth_controller.dart';
import 'package:chewata/models/chat_model.dart';
import 'package:chewata/models/user_model.dart';

class FunScreen extends StatefulWidget {
  const FunScreen({Key? key}) : super(key: key);

  @override
  State<FunScreen> createState() => _FunScreenState();
}

class _FunScreenState extends State<FunScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _groupNameController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _animation;
  final RxList<ChatModel> _groupChats = <ChatModel>[].obs;
  final RxBool _isLoading = true.obs;
  final AuthController _authController = Get.find<AuthController>();
  StreamSubscription<QuerySnapshot>? _groupsSub;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _subscribeGroupChats();
  }

  void _subscribeGroupChats() {
    try {
      final currentUserId = _authController.currentUser.value?.id;
      if (currentUserId == null) {
        _isLoading.value = false;
        return;
      }
      _isLoading.value = true;
      _groupsSub = FirebaseFirestore.instance
          .collection('chats')
          .where('isGroupChat', isEqualTo: true)
          .where('participants', arrayContains: currentUserId)
          // Avoid orderBy here to not require composite index; sort client-side
          .snapshots()
          .listen(
            (snap) {
              final list =
                  snap.docs
                      .map((d) => ChatModel.fromMap(d.data(), d.id))
                      .toList();
              list.sort((a, b) {
                final at = a.lastMessageTime ?? a.createdAt;
                final bt = b.lastMessageTime ?? b.createdAt;
                return bt.compareTo(at);
              });
              _groupChats.value = list;
              _isLoading.value = false;
            },
            onError: (_) {
              _isLoading.value = false;
            },
          );
    } catch (e) {
      _isLoading.value = false;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _groupNameController.dispose();
    _groupsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Obx(
        () =>
            _isLoading.value
                ? _buildLoadingView()
                : _buildGroupChatList(isDarkMode),
      ),
      floatingActionButton: FadeTransition(
        opacity: _animation,
        child: FloatingActionButton.extended(
          onPressed: () => _showCreateGroupDialog(context),
          label: const Text('Create Group'),
          icon: const Icon(Icons.group_add),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _animation,
            child: const Icon(
              Icons.groups_rounded,
              size: 80,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Loading Group Chats...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupChatList(bool isDarkMode) {
    return Obx(() {
      if (_groupChats.isEmpty) {
        return _buildEmptyState();
      }

      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: _groupChats.length,
        itemBuilder: (context, index) {
          final chat = _groupChats[index];
          return _buildGroupChatTile(chat, isDarkMode);
        },
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.groups_rounded,
            size: 120,
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
          ),
          const SizedBox(height: 24),
          Text(
            'No Group Chats Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Create your first group chat and start having fun with friends!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => _showCreateGroupDialog(context),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Create a Group Chat'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupChatTile(ChatModel chat, bool isDarkMode) {
    // Generate a consistent color for the group avatar based on the group name
    final color = Color((chat.id.hashCode & 0xFFFFFF) | 0xFF000000);

    // Calculate how many members to show in the avatar stack
    final memberCount = chat.participants.length;
    // final showCount = math.min(memberCount, 3);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openGroupChat(chat),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Group avatar with stacked member avatars
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    children: [
                      // Base circle with group initial
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withOpacity(0.2),
                          border: Border.all(color: color, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            (chat.groupName != null &&
                                    chat.groupName!.isNotEmpty)
                                ? chat.groupName!.substring(0, 1).toUpperCase()
                                : 'G',
                            style: TextStyle(
                              color: color,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      // Member count badge
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  isDarkMode ? Colors.grey[850]! : Colors.white,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            memberCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Group info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chat.groupName ?? 'Group Chat',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last message: ${chat.lastMessageText ?? 'No messages yet'}',
                        style: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color:
                                isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDateTime(chat.lastMessageTime),
                            style: TextStyle(
                              color:
                                  isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Unread count indicator
                if ((chat.unreadCount[_authController.currentUser.value?.id] ??
                        0) >
                    0)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${chat.unreadCount[_authController.currentUser.value?.id]}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Just now';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _openGroupChat(ChatModel chat) {
    // Navigate to group chat screen
    Get.toNamed('/group-chat/${chat.id}');
  }

  void _showCreateGroupDialog(BuildContext context) {
    final selectedUsers = <UserModel>[].obs;

    Future<List<UserModel>> _getPriorContacts() async {
      try {
        final meId = _authController.currentUser.value?.id;
        if (meId == null) return [];

        // Fetch chats where current user is a participant (both legacy and new)
        final chatsSnap =
            await FirebaseFirestore.instance
                .collection('chats')
                .where('participants', arrayContains: meId)
                .get();

        final otherIds = <String>{};
        for (final d in chatsSnap.docs) {
          final data = d.data();
          // Only consider 1:1 chats: exactly two participants including me
          final parts = List<String>.from(data['participants'] ?? const []);
          if (parts.length == 2 && parts.contains(meId)) {
            final other = parts.firstWhere((p) => p != meId);
            otherIds.add(other);
          }
        }

        if (otherIds.isEmpty) return [];

        // Fetch users by chunks of 10 doc IDs (Firestore whereIn limit)
        final ids = otherIds.toList();
        final List<UserModel> users = [];
        for (var i = 0; i < ids.length; i += 10) {
          final chunk = ids.sublist(
            i,
            (i + 10 > ids.length) ? ids.length : i + 10,
          );
          final snap =
              await FirebaseFirestore.instance
                  .collection('users')
                  .where(FieldPath.documentId, whereIn: chunk)
                  .get();
          for (final doc in snap.docs) {
            final data = doc.data();
            var user = UserModel.fromMap(data);
            if (user.id.isEmpty) user = user.copyWith(id: doc.id);
            users.add(user);
          }
        }

        return users;
      } catch (_) {
        return [];
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return DraggableScrollableSheet(
                initialChildSize: 0.7,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                builder: (_, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Create Group Chat',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _groupNameController,
                          decoration: InputDecoration(
                            labelText: 'Group Name',
                            hintText: 'Enter a name for your group',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.group),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Select Members',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Selected users chips
                        Obx(
                          () =>
                              selectedUsers.isNotEmpty
                                  ? Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children:
                                        selectedUsers
                                            .map(
                                              (user) => Chip(
                                                avatar: CircleAvatar(
                                                  backgroundImage: NetworkImage(
                                                    user.profilePicUrl,
                                                  ),
                                                  onBackgroundImageError:
                                                      (_, __) => const Icon(
                                                        Icons.person,
                                                      ),
                                                ),
                                                label: Text(user.fullName),
                                                deleteIcon: const Icon(
                                                  Icons.close,
                                                  size: 16,
                                                ),
                                                onDeleted:
                                                    () => selectedUsers.remove(
                                                      user,
                                                    ),
                                              ),
                                            )
                                            .toList(),
                                  )
                                  : const SizedBox.shrink(),
                        ),

                        const SizedBox(height: 10),

                        // User list for selection
                        Expanded(
                          child: FutureBuilder<List<UserModel>>(
                            future: _getPriorContacts(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final users = snapshot.data ?? [];
                              if (users.isEmpty) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24.0,
                                    ),
                                    child: Text(
                                      'No prior contacts yet. Start a private chat first, then you can add them to a group.',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                );
                              }

                              return ListView.builder(
                                controller: scrollController,
                                itemCount: users.length,
                                itemBuilder: (context, index) {
                                  final user = users[index];
                                  final isSelected = selectedUsers.contains(
                                    user,
                                  );

                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage: NetworkImage(
                                        user.profilePicUrl,
                                      ),
                                      onBackgroundImageError:
                                          (_, __) => const Icon(Icons.person),
                                    ),
                                    title: Text(user.fullName),
                                    subtitle: Text(user.email),
                                    trailing: Checkbox(
                                      value: isSelected,
                                      onChanged: (value) {
                                        if (value == true) {
                                          selectedUsers.add(user);
                                        } else {
                                          selectedUsers.remove(user);
                                        }
                                      },
                                    ),
                                    onTap: () {
                                      if (isSelected) {
                                        selectedUsers.remove(user);
                                      } else {
                                        selectedUsers.add(user);
                                      }
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Create group button
                        SizedBox(
                          width: double.infinity,
                          child: Obx(
                            () => ElevatedButton(
                              onPressed:
                                  selectedUsers.isEmpty
                                      ? null
                                      : () => _createGroupChat(selectedUsers),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                'Create Group',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
    );
  }

  void _createGroupChat(RxList<UserModel> selectedUsers) async {
    if (_groupNameController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a group name',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      final currentUserId = _authController.currentUser.value!.id;

      // Create participant list including current user
      final participants = <String>[
        currentUserId,
        ...selectedUsers.map((user) => user.id),
      ];

      // Create unread count map
      final unreadCount = <String, int>{};
      for (final userId in participants) {
        unreadCount[userId] = 0;
      }

      // Create new group chat document
      final chatRef = FirebaseFirestore.instance.collection('chats').doc();
      final newChat = ChatModel(
        id: chatRef.id,
        participants: participants,
        createdAt: DateTime.now(),
        lastMessageTime: DateTime.now(),
        lastMessageText: null,
        lastMessageSenderId: currentUserId,
        unreadCount: unreadCount,
        isGroupChat: true,
        groupName: _groupNameController.text.trim(),
        groupCreatorId: currentUserId,
        groupCreatedAt: DateTime.now(),
        groupAdmins: [currentUserId],
      );

      // Add group chat specific fields
      await chatRef.set(newChat.toMap());

      // Create welcome message
      await FirebaseFirestore.instance.collection('messages').add({
        'chatId': chatRef.id,
        'senderId': currentUserId,
        'text': 'Welcome to ${_groupNameController.text.trim()} group!',
        'sentAt': DateTime.now(),
        'isRead': false,
        'isDelivered': false,
        'metadata': {'isSystemMessage': true},
      });

      // Close dialog and navigate to the new group chat
      Get.back();
      _groupNameController.clear();
      // no-op; stream will update list
      Get.toNamed('/group-chat/${chatRef.id}');
    } catch (e) {
      print('Error creating group chat: $e');
      Get.snackbar(
        'Error',
        'Failed to create group chat',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
