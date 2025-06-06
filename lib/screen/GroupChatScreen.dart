import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chewata/models/chat_model.dart';
import 'package:chewata/models/message_model.dart';
import 'package:chewata/models/user_model.dart';
import 'package:chewata/controller/auth_controller.dart';
import 'dart:math' as math;

class GroupChatScreen extends StatefulWidget {
  final String chatId;
  
  const GroupChatScreen({
    Key? key,
    required this.chatId,
  }) : super(key: key);

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final RxBool _isLoading = true.obs;
  final Rx<ChatModel?> _groupChat = Rx<ChatModel?>(null);
  final RxList<MessageModel> _messages = <MessageModel>[].obs;
  final RxMap<String, UserModel> _userCache = <String, UserModel>{}.obs;
  
  final AuthController _authController = Get.find<AuthController>();
  
  late AnimationController _sendButtonAnimController;
  late Animation<double> _sendButtonAnim;
  
  @override
  void initState() {
    super.initState();
    
    _sendButtonAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _sendButtonAnim = CurvedAnimation(
      parent: _sendButtonAnimController,
      curve: Curves.easeInOut,
    );
    
    _loadGroupChat();
    _setupMessageListener();
    
    _messageController.addListener(() {
      if (_messageController.text.isNotEmpty) {
        _sendButtonAnimController.forward();
      } else {
        _sendButtonAnimController.reverse();
      }
    });
  }
  
  @override
  void dispose() {
    _sendButtonAnimController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _loadGroupChat() async {
    try {
      _isLoading.value = true;
      
      // Get the group chat document
      final doc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .get();
      
      if (!doc.exists) {
        Get.snackbar(
          'Error',
          'Group chat not found',
          snackPosition: SnackPosition.BOTTOM,
        );
        Get.back();
        return;
      }
      
      // Create chat model
      _groupChat.value = ChatModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
      
      // Reset unread count for current user
      if (_groupChat.value != null) {
        final currentUserId = _authController.currentUser.value!.id;
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chatId)
            .update({
          'unreadCount.$currentUserId': 0,
        });
        
        // Prefetch user data for participants
        for (final userId in _groupChat.value!.participants) {
          _fetchUserData(userId);
        }
      }
      
      _isLoading.value = false;
    } catch (e) {
      print('Error loading group chat: $e');
      _isLoading.value = false;
    }
  }
  
  void _setupMessageListener() {
    FirebaseFirestore.instance
        .collection('messages')
        .where('chatId', isEqualTo: widget.chatId)
        .orderBy('sentAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      final messages = snapshot.docs
          .map((doc) => MessageModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ))
          .toList();
      
      _messages.value = messages;
      
      // Mark messages as read
      _markMessagesAsRead(messages);
      
      // Fetch user data for any new message senders
      for (final message in messages) {
        if (!_userCache.containsKey(message.senderId)) {
          _fetchUserData(message.senderId);
        }
      }
      
      // Scroll to bottom if new message is from current user
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_messages.isNotEmpty && 
            _messages.first.senderId == _authController.currentUser.value?.id) {
          _scrollToBottom();
        }
      });
    });
  }
  
  void _fetchUserData(String userId) async {
    try {
      if (_userCache.containsKey(userId)) return;
      
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (doc.exists) {
        final userData = doc.data() as Map<String, dynamic>;
        _userCache[userId] = UserModel.fromMap(userData);
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }
  
  void _markMessagesAsRead(List<MessageModel> messages) async {
    final currentUserId = _authController.currentUser.value?.id;
    if (currentUserId == null) return;
    
    final batch = FirebaseFirestore.instance.batch();
    bool hasUnreadMessages = false;
    
    for (final message in messages) {
      if (!message.isRead && message.senderId != currentUserId) {
        final messageRef = FirebaseFirestore.instance
            .collection('messages')
            .doc(message.id);
        
        batch.update(messageRef, {'isRead': true});
        hasUnreadMessages = true;
      }
    }
    
    if (hasUnreadMessages) {
      await batch.commit();
    }
  }
  
  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    final currentUser = _authController.currentUser.value;
    if (currentUser == null) return;
    
    try {
      // Clear text field first for better UX
      _messageController.clear();
      
      // Create new message
      final newMessage = {
        'chatId': widget.chatId,
        'senderId': currentUser.id,
        'text': text,
        'sentAt': DateTime.now(),
        'isRead': false,
        'isDelivered': false,
      };
      
      // Add message to Firestore
      await FirebaseFirestore.instance
          .collection('messages')
          .add(newMessage);
      
      // Update chat's last message data
      final unreadCountUpdates = <String, dynamic>{};
      for (final userId in _groupChat.value!.participants) {
        if (userId != currentUser.id) {
          unreadCountUpdates['unreadCount.$userId'] = FieldValue.increment(1);
        }
      }
      
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'lastMessageText': text,
        'lastMessageTime': DateTime.now(),
        'lastMessageSenderId': currentUser.id,
        ...unreadCountUpdates,
      });
      
      // Scroll to bottom
      _scrollToBottom();
    } catch (e) {
      print('Error sending message: $e');
      Get.snackbar(
        'Error',
        'Failed to send message',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: _buildAppBar(isDarkMode),
      body: Obx(() => _isLoading.value 
        ? const Center(child: CircularProgressIndicator())
        : _buildChatUI(isDarkMode)
      ),
    );
  }
  
  PreferredSizeWidget _buildAppBar(bool isDarkMode) {
    return AppBar(
      title: Obx(() {
        if (_isLoading.value || _groupChat.value == null) {
          return const Text('Group Chat');
        }
        
        final groupName = (_groupChat.value?.toMap()['groupName'] as String?) ?? 'Group Chat';
        
        return Row(
          children: [
            // Group avatar with random color
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(
                  (widget.chatId.hashCode & 0xFFFFFF) | 0xFF000000,
                ).withOpacity(0.2),
                border: Border.all(
                  color: Color((widget.chatId.hashCode & 0xFFFFFF) | 0xFF000000),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  groupName.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: Color((widget.chatId.hashCode & 0xFFFFFF) | 0xFF000000),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    groupName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${_groupChat.value!.participants.length} members',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => _showGroupInfo(context),
        ),
      ],
    );
  }
  
  Widget _buildChatUI(bool isDarkMode) {
    return Column(
      children: [
        // Messages list
        Expanded(
          child: Obx(() {
            if (_messages.isEmpty) {
              return _buildEmptyChat();
            }
            
            return ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isCurrentUser = message.senderId == _authController.currentUser.value?.id;
                
                // Show date separator if needed
                final showDateSeparator = index == _messages.length - 1 || 
                    !_isSameDay(message.sentAt, _messages[index + 1].sentAt);
                
                return Column(
                  children: [
                    if (showDateSeparator)
                      _buildDateSeparator(message.sentAt),
                    _buildMessageBubble(message, isCurrentUser, isDarkMode),
                  ],
                );
              },
            );
          }),
        ),
        
        // Message input
        _buildMessageInput(isDarkMode),
      ],
    );
  }
  
  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start the conversation!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDateSeparator(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _formatDateForSeparator(date),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
  
  Widget _buildMessageBubble(MessageModel message, bool isCurrentUser, bool isDarkMode) {
    final sender = _userCache[message.senderId];
    final isSystemMessage = (message.metadata?['isSystemMessage'] as bool?) ?? false;
    
    // System messages are centered
    if (isSystemMessage) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.white70 : Colors.black87,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Show avatar for other users
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: sender != null
                  ? NetworkImage(sender.profilePicUrl)
                  : null,
              child: sender == null ? const Icon(Icons.person, size: 16) : null,
            ),
            const SizedBox(width: 8),
          ],
          
          // Message bubble
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? Theme.of(context).colorScheme.primary
                    : isDarkMode ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isCurrentUser ? const Radius.circular(20) : const Radius.circular(0),
                  bottomRight: isCurrentUser ? const Radius.circular(0) : const Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show sender name for group chats (if not current user)
                  if (!isCurrentUser && sender != null) ...[
                    Text(
                      sender.fullName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isCurrentUser
                            ? Colors.white70
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  
                  // Message text
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isCurrentUser
                          ? Colors.white
                          : isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  
                  // Time and read status
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(message.sentAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: isCurrentUser
                              ? Colors.white70
                              : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (isCurrentUser)
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 12,
                          color: message.isRead ? Colors.blue[300] : Colors.white70,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Show avatar for current user (at the end)
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundImage: _authController.currentUser.value?.profilePicUrl != null
                  ? NetworkImage(_authController.currentUser.value!.profilePicUrl)
                  : null,
              child: _authController.currentUser.value?.profilePicUrl == null
                  ? const Icon(Icons.person, size: 16)
                  : null,
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildMessageInput(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: SafeArea(
        child: Row(
          children: [
            // Attach button
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: () {
                // Show attachment options
                _showAttachmentOptions(context);
              },
            ),
            
            // Message text field
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
                    vertical: 8,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                textInputAction: TextInputAction.newline,
              ),
            ),
            
            // Send button with animation
            ScaleTransition(
              scale: _sendButtonAnim,
              child: IconButton(
                icon: const Icon(Icons.send),
                color: Theme.of(context).colorScheme.primary,
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showGroupInfo(BuildContext context) {
    if (_groupChat.value == null) return;
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final groupName = (_groupChat.value?.toMap()['groupName'] as String?) ?? 'Group Chat';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[900] : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Group info header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Group avatar
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color((widget.chatId.hashCode & 0xFFFFFF) | 0xFF000000)
                              .withOpacity(0.2),
                          border: Border.all(
                            color: Color((widget.chatId.hashCode & 0xFFFFFF) | 0xFF000000),
                            width: 3,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            groupName.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: Color((widget.chatId.hashCode & 0xFFFFFF) | 0xFF000000),
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Group name
                      Text(
                        groupName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Group created info
                      Text(
                        'Created on ${_formatDateLong(_groupChat.value!.createdAt)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Member count
                      Text(
                        '${_groupChat.value!.participants.length} members',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Divider(),
                
                // Members list
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _groupChat.value!.participants.length,
                    itemBuilder: (context, index) {
                      final userId = _groupChat.value!.participants[index];
                      final user = _userCache[userId];
                      final isAdmin = userId == _groupChat.value!.toMap()['groupCreatorId'];
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user?.profilePicUrl != null
                              ? NetworkImage(user!.profilePicUrl)
                              : null,
                          child: user?.profilePicUrl == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Row(
                          children: [
                            Text(
                              user?.fullName ?? 'Loading...',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (isAdmin) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Admin',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(user?.email ?? ''),
                        trailing: userId == _authController.currentUser.value?.id
                            ? const Text('You')
                            : null,
                      );
                    },
                  ),
                ),
                
                // Actions
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.exit_to_app,
                        label: 'Leave Group',
                        color: Colors.red,
                        onTap: () => _leaveGroup(),
                      ),
                      if (_groupChat.value!.toMap()['groupCreatorId'] == 
                          _authController.currentUser.value?.id)
                        _buildActionButton(
                          icon: Icons.edit,
                          label: 'Edit Group',
                          color: Theme.of(context).colorScheme.primary,
                          onTap: () => _editGroup(context),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showAttachmentOptions(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share Content',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.image,
                  label: 'Gallery',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    // Implement image picker
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    // Implement camera
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.insert_drive_file,
                  label: 'Document',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    // Implement document picker
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.location_on,
                  label: 'Location',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    // Implement location sharing
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  void _leaveGroup() {
    // Show confirmation dialog
    Get.dialog(
      AlertDialog(
        title: const Text('Leave Group'),
        content: const Text(
          'Are you sure you want to leave this group? You\'ll no longer receive messages from this group.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Get.back(); // Close dialog
              
              try {
                final currentUserId = _authController.currentUser.value!.id;
                
                // Remove user from participants
                final updatedParticipants = _groupChat.value!.participants
                    .where((id) => id != currentUserId)
                    .toList();
                
                // Update chat document
                await FirebaseFirestore.instance
                    .collection('chats')
                    .doc(widget.chatId)
                    .update({
                  'participants': updatedParticipants,
                });
                
                // Add system message
                await FirebaseFirestore.instance
                    .collection('messages')
                    .add({
                  'chatId': widget.chatId,
                  'senderId': currentUserId,
                  'text': '${_authController.currentUser.value!.fullName} left the group',
                  'sentAt': DateTime.now(),
                  'isRead': false,
                  'isDelivered': false,
                  'metadata': {
                    'isSystemMessage': true,
                  },
                });
                
                // Navigate back
                Get.back();
                
              } catch (e) {
                print('Error leaving group: $e');
                Get.snackbar(
                  'Error',
                  'Failed to leave the group',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: const Text(
              'Leave',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
  
  void _editGroup(BuildContext context) {
    final groupName = (_groupChat.value?.toMap()['groupName'] as String?) ?? 'Group Chat';
    final nameController = TextEditingController(text: groupName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Group'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Group Name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isEmpty) return;
              
              try {
                await FirebaseFirestore.instance
                    .collection('chats')
                    .doc(widget.chatId)
                    .update({
                  'groupName': newName,
                });
                
                // Add system message
                await FirebaseFirestore.instance
                    .collection('messages')
                    .add({
                  'chatId': widget.chatId,
                  'senderId': _authController.currentUser.value!.id,
                  'text': 'Group name changed to "$newName"',
                  'sentAt': DateTime.now(),
                  'isRead': false,
                  'isDelivered': false,
                  'metadata': {
                    'isSystemMessage': true,
                  },
                });
                
                Navigator.pop(context);
                Get.back(); // Close group info sheet
                
              } catch (e) {
                print('Error updating group name: $e');
                Get.snackbar(
                  'Error',
                  'Failed to update group name',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  
  String _formatDateForSeparator(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    } else if (date.year == yesterday.year && 
               date.month == yesterday.month && 
               date.day == yesterday.day) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  
  String _formatDateLong(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
  
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }
}