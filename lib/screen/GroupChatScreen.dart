import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chewata/models/chat_model.dart';
import 'package:chewata/models/message_model.dart';
import 'package:chewata/models/user_model.dart';
import 'package:chewata/controller/auth_controller.dart';

class GroupChatScreen extends StatefulWidget {
  final String chatId;

  const GroupChatScreen({Key? key, required this.chatId}) : super(key: key);

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final RxBool _isLoading = true.obs;
  final Rx<ChatModel?> _groupChat = Rx<ChatModel?>(null);
  final RxList<MessageModel> _messages = <MessageModel>[].obs;
  final RxMap<String, UserModel> _userCache = <String, UserModel>{}.obs;

  final AuthController _authController = Get.find<AuthController>();

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _chatSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _msgSub;

  @override
  void initState() {
    super.initState();
    _listenGroupChat();
    _listenMessages();
  }

  @override
  void dispose() {
    _chatSub?.cancel();
    _msgSub?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _listenGroupChat() {
    _chatSub = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .snapshots()
        .listen((doc) {
          if (!doc.exists) {
            _isLoading.value = false;
            return;
          }
          _groupChat.value = ChatModel.fromMap(doc.data()!, doc.id);
          _isLoading.value = false;
          // Preload members
          for (final uid in _groupChat.value!.participants) {
            _ensureUserLoaded(uid);
          }
        });
  }

  void _listenMessages() {
    _msgSub = FirebaseFirestore.instance
        .collection('messages')
        .where('chatId', isEqualTo: widget.chatId)
        .snapshots()
        .listen((snap) async {
          final msgs =
              snap.docs
                  .map((d) => MessageModel.fromMap(d.data(), d.id))
                  .toList();
          msgs.sort((a, b) => a.sentAt.compareTo(b.sentAt));
          _messages.value = msgs;
          _scrollToBottom();
          await _markMessagesAsRead();
          // Ensure senders cached
          for (final m in msgs) {
            _ensureUserLoaded(m.senderId);
          }
        });
  }

  Future<void> _ensureUserLoaded(String userId) async {
    if (_userCache.containsKey(userId)) return;
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
      if (doc.exists) {
        final data = doc.data()!;
        var user = UserModel.fromMap(data);
        if (user.id.isEmpty) {
          user = user.copyWith(id: doc.id);
        }
        _userCache[userId] = user;
      }
    } catch (_) {}
  }

  Future<void> _markMessagesAsRead() async {
    final currentUserId = _authController.currentUser.value?.id;
    final chat = _groupChat.value;
    if (currentUserId == null || chat == null) return;
    final batch = FirebaseFirestore.instance.batch();

    for (final m in _messages) {
      if (!m.isRead && m.senderId != currentUserId) {
        final ref = FirebaseFirestore.instance.collection('messages').doc(m.id);
        batch.update(ref, {'isRead': true});
      }
    }

    // reset my unread counter
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chat.id);
    batch.update(chatRef, {'unreadCount.$currentUserId': 0});
    await batch.commit();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final chat = _groupChat.value;
    final currentUser = _authController.currentUser.value;
    if (chat == null || currentUser == null) return;

    try {
      final now = DateTime.now();
      final msgRef = FirebaseFirestore.instance.collection('messages').doc();
      final chatRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(chat.id);

      await FirebaseFirestore.instance.runTransaction((tx) async {
        tx.set(msgRef, {
          'chatId': chat.id,
          'senderId': currentUser.id,
          'text': text,
          'sentAt': now,
          'isRead': false,
          'isDelivered': true,
          'isDeleted': false,
          'isEdited': false,
          'editedAt': null,
          'deletedAt': null,
          'metadata': {'isSystemMessage': false},
        });

        // increment unread for others
        final updateMap = <String, dynamic>{
          'lastMessageTime': now,
          'lastMessageText': text,
          'lastMessageSenderId': currentUser.id,
        };
        for (final uid in chat.participants) {
          if (uid == currentUser.id) continue;
          updateMap['unreadCount.$uid'] = FieldValue.increment(1);
        }
        tx.update(chatRef, updateMap);
      });

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      Get.snackbar('Error', 'Failed to send message');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Obx(() {
      if (_isLoading.value) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final chat = _groupChat.value;
      if (chat == null) {
        return const Scaffold(
          body: Center(child: Text('Group chat not found')),
        );
      }
      return Scaffold(
        appBar: AppBar(
          title: Text(chat.groupName ?? 'Group Chat'),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _showGroupInfo,
            ),
            PopupMenuButton<String>(
              onSelected: _onMenuSelected,
              itemBuilder: (ctx) {
                final me = _authController.currentUser.value?.id;
                final isAdmin = _isAdmin(me, chat);
                final isCreator = chat.groupCreatorId == me;
                final items = <PopupMenuEntry<String>>[];
                if (isAdmin) {
                  items.add(
                    const PopupMenuItem(
                      value: 'rename',
                      child: Text('Rename group'),
                    ),
                  );
                }
                if (isAdmin) {
                  items.add(
                    const PopupMenuItem(
                      value: 'manage',
                      child: Text('Manage members'),
                    ),
                  );
                }
                if (isCreator) {
                  items.add(
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete group'),
                    ),
                  );
                }
                items.add(
                  const PopupMenuItem(
                    value: 'leave',
                    child: Text('Leave group'),
                  ),
                );
                return items;
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isMe =
                      msg.senderId == _authController.currentUser.value?.id;
                  final isSystem =
                      (msg.metadata?['isSystemMessage'] as bool?) ?? false;

                  // Date separator
                  Widget? sep;
                  if (index == 0 ||
                      !_isSameDay(_messages[index - 1].sentAt, msg.sentAt)) {
                    sep = _buildDateChip(msg.sentAt);
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (sep != null) sep,
                      Align(
                        alignment:
                            isSystem
                                ? Alignment.center
                                : isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  isSystem
                                      ? Colors.grey.withOpacity(0.2)
                                      : isMe
                                      ? Theme.of(context).colorScheme.primary
                                      : (isDarkMode
                                          ? Colors.grey[800]
                                          : Colors.grey[200]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMe && !isSystem)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Text(
                                      _userCache[msg.senderId]?.fullName ??
                                          'User',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            isDarkMode
                                                ? Colors.grey[300]
                                                : Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                Text(
                                  msg.text,
                                  style: TextStyle(
                                    color:
                                        isSystem
                                            ? (isDarkMode
                                                ? Colors.grey[300]
                                                : Colors.grey[700])
                                            : isMe
                                            ? Colors.white
                                            : (isDarkMode
                                                ? Colors.white
                                                : Colors.black87),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    _formatTime(msg.sentAt),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color:
                                          isSystem
                                              ? (isDarkMode
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600])
                                              : (isMe
                                                  ? Colors.white70
                                                  : (isDarkMode
                                                      ? Colors.grey[400]
                                                      : Colors.grey[600])),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            _buildInputBar(isDarkMode),
          ],
        ),
      );
    });
  }

  Widget _buildDateChip(DateTime date) {
    final text = _formatDateLong(date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(text, style: const TextStyle(fontSize: 12)),
        ),
      ),
    );
  }

  Widget _buildInputBar(bool isDarkMode) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Message',
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[850] : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send_rounded),
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _showGroupInfo() {
    final chat = _groupChat.value;
    if (chat == null) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chat.groupName ?? 'Group',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Members',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...chat.participants.map((uid) {
                  final u = _userCache[uid];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        (u?.fullName ?? 'U').substring(0, 1).toUpperCase(),
                      ),
                    ),
                    title: Text(u?.fullName ?? 'User'),
                    subtitle: Text(u?.email ?? ''),
                  );
                }),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isAdmin(String? userId, ChatModel chat) {
    if (userId == null) return false;
    return chat.groupAdmins.contains(userId) || chat.groupCreatorId == userId;
  }

  void _onMenuSelected(String key) {
    switch (key) {
      case 'rename':
        _renameGroup();
        break;
      case 'manage':
        _manageMembers();
        break;
      case 'leave':
        _leaveGroup();
        break;
      case 'delete':
        _deleteGroup();
        break;
    }
  }

  Future<void> _renameGroup() async {
    final chat = _groupChat.value;
    final me = _authController.currentUser.value?.id;
    if (chat == null || !_isAdmin(me, chat)) return;
    final controller = TextEditingController(text: chat.groupName ?? '');
    final name = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Rename group'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Group name'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                child: const Text('Save'),
              ),
            ],
          ),
    );
    if (name == null || name.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('chats').doc(chat.id).update({
        'groupName': name,
      });
      Get.snackbar('Updated', 'Group renamed');
    } catch (_) {
      Get.snackbar('Error', 'Failed to rename group');
    }
  }

  Future<void> _manageMembers() async {
    final chat = _groupChat.value;
    final me = _authController.currentUser.value?.id;
    if (chat == null || !_isAdmin(me, chat)) return;

    // Load all member user models
    final members = <UserModel>[];
    for (final id in chat.participants) {
      if (_userCache.containsKey(id)) {
        members.add(_userCache[id]!);
      } else {
        final doc =
            await FirebaseFirestore.instance.collection('users').doc(id).get();
        if (doc.exists) {
          final u = UserModel.fromMap(doc.data()!);
          members.add(u);
          _userCache[id] = u;
        }
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Column(
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Manage members',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: members.length,
                    itemBuilder: (c, i) {
                      final u = members[i];
                      final isAdmin =
                          chat.groupAdmins.contains(u.id) ||
                          chat.groupCreatorId == u.id;
                      final isMe = u.id == me;
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            u.fullName.isNotEmpty
                                ? u.fullName[0].toUpperCase()
                                : 'U',
                          ),
                        ),
                        title: Text(u.fullName),
                        subtitle: Text(isAdmin ? 'Admin' : 'Member'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isMe && me == chat.groupCreatorId)
                              IconButton(
                                icon: Icon(
                                  isAdmin
                                      ? Icons.person_remove_alt_1
                                      : Icons.person_add_alt_1,
                                ),
                                tooltip:
                                    isAdmin
                                        ? 'Demote from admin'
                                        : 'Make admin',
                                onPressed: () async {
                                  await _toggleAdmin(u.id, add: !isAdmin);
                                  Navigator.pop(ctx);
                                },
                              ),
                            if (!isMe)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                tooltip: 'Remove from group',
                                onPressed: () async {
                                  await _removeMember(u.id);
                                  Navigator.pop(ctx);
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _toggleAdmin(String userId, {required bool add}) async {
    final chat = _groupChat.value;
    final me = _authController.currentUser.value?.id;
    if (chat == null || me != chat.groupCreatorId) return; // only creator
    final ref = FirebaseFirestore.instance.collection('chats').doc(chat.id);
    try {
      await ref.update({
        'groupAdmins':
            add
                ? FieldValue.arrayUnion([userId])
                : FieldValue.arrayRemove([userId]),
      });
      Get.snackbar('Updated', add ? 'Admin added' : 'Admin removed');
    } catch (_) {
      Get.snackbar('Error', 'Failed to update admins');
    }
  }

  Future<void> _removeMember(String userId) async {
    final chat = _groupChat.value;
    final me = _authController.currentUser.value?.id;
    if (chat == null || !_isAdmin(me, chat)) return;
    if (userId == chat.groupCreatorId) {
      Get.snackbar('Not allowed', 'Creator cannot be removed');
      return;
    }
    final ref = FirebaseFirestore.instance.collection('chats').doc(chat.id);
    try {
      await ref.update({
        'participants': FieldValue.arrayRemove([userId]),
        'groupAdmins': FieldValue.arrayRemove([userId]),
        'unreadCount.$userId': FieldValue.delete(),
      });
      Get.snackbar('Removed', 'Member removed');
    } catch (_) {
      Get.snackbar('Error', 'Failed to remove member');
    }
  }

  Future<void> _leaveGroup() async {
    final chat = _groupChat.value;
    final me = _authController.currentUser.value?.id;
    if (chat == null || me == null) return;
    if (me == chat.groupCreatorId) {
      Get.snackbar(
        'Action needed',
        'Creators must delete the group or transfer ownership',
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Leave group?'),
            content: const Text('You will stop receiving messages.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Leave'),
              ),
            ],
          ),
    );
    if (ok != true) return;
    try {
      final ref = FirebaseFirestore.instance.collection('chats').doc(chat.id);
      await ref.update({
        'participants': FieldValue.arrayRemove([me]),
        'groupAdmins': FieldValue.arrayRemove([me]),
        'unreadCount.$me': FieldValue.delete(),
      });
      Get.back(); // leave screen
      Get.snackbar('Left', 'You left the group');
    } catch (_) {
      Get.snackbar('Error', 'Failed to leave group');
    }
  }

  Future<void> _deleteGroup() async {
    final chat = _groupChat.value;
    final me = _authController.currentUser.value?.id;
    if (chat == null || me != chat.groupCreatorId) return; // only creator
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete group?'),
            content: const Text('This will permanently delete all messages.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (ok != true) return;
    try {
      final db = FirebaseFirestore.instance;
      final chatRef = db.collection('chats').doc(chat.id);
      // Delete messages in batches
      final msgs =
          await db
              .collection('messages')
              .where('chatId', isEqualTo: chat.id)
              .get();
      final batch = db.batch();
      for (final d in msgs.docs) {
        batch.delete(d.reference);
      }
      batch.delete(chatRef);
      await batch.commit();
      Get.back();
      Get.snackbar('Deleted', 'Group deleted');
    } catch (_) {
      Get.snackbar('Error', 'Failed to delete group');
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateLong(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(dt.year, dt.month, dt.day);
    if (dateOnly == today) return 'Today';
    if (dateOnly == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
