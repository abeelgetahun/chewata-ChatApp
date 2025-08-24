import 'dart:async';

import 'package:get/get.dart';
import 'package:chewata/models/chat_model.dart';
import 'package:chewata/models/message_model.dart';
import 'package:chewata/models/user_model.dart';
import 'package:chewata/services/chat_service.dart';
import 'package:chewata/services/auth_service.dart';

class ChatController extends GetxController {
  final ChatService _chatService = ChatService.instance;
  final AuthService _authService = AuthService.instance;

  // Reactive variables
  final RxList<ChatModel> userChats = <ChatModel>[].obs;
  final RxList<MessageModel> currentChatMessages = <MessageModel>[].obs;
  final RxMap<String, UserModel> chatUsers = <String, UserModel>{}.obs;
  final RxString selectedChatId = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isSearching = false.obs;
  final RxBool isLoadingMessages = false.obs;
  final Rx<UserModel?> searchedUser = Rx<UserModel?>(null);

  final RxBool isInitialLoading = true.obs;
  final RxInt chatBatchSize = 10.obs;
  final RxInt currentChatBatchIndex = 0.obs;
  final RxBool hasMoreChats = true.obs;
  List<ChatModel> _allChats = [];

  // Add a map to track active subscriptions
  final Map<String, StreamSubscription> _statusSubscriptions = {};

  // Store the current user for convenience
  UserModel? get currentUser => _authService.userModel.value;

  @override
  void onInit() {
    super.onInit();

    // Only listen to chats when user is authenticated
    _authService.userModel.listen((user) {
      if (user != null) {
        _listenToUserChats();
      } else {
        // Clear data when user logs out
        userChats.clear();
        chatUsers.clear();
        selectedChatId.value = '';
        currentChatMessages.clear();
      }
    });
  }

  // Listen for user chats
  void _listenToUserChats() {
    isInitialLoading.value = true;

    _chatService.getUserChats().listen((chats) {
      _allChats = chats;

      // Reset pagination state
      currentChatBatchIndex.value = 0;
      hasMoreChats.value = true;

      // Load the first batch
      _loadNextChatBatch();

      isInitialLoading.value = false;
    });
  }

  // Add this new method for lazy loading
  void _loadNextChatBatch() {
    if (!hasMoreChats.value) return;

    final startIndex = currentChatBatchIndex.value * chatBatchSize.value;
    final endIndex = startIndex + chatBatchSize.value;

    if (startIndex >= _allChats.length) {
      hasMoreChats.value = false;
      return;
    }

    final batch = _allChats.sublist(
      startIndex,
      endIndex > _allChats.length ? _allChats.length : endIndex,
    );

    // If this is the first batch, replace the list
    if (currentChatBatchIndex.value == 0) {
      userChats.value = batch;
    } else {
      // Otherwise, add to existing list
      userChats.addAll(batch);
    }

    // Update index
    currentChatBatchIndex.value++;

    // Update hasMore flag
    hasMoreChats.value = endIndex < _allChats.length;

    // Load user info for each chat participant in this batch
    for (final chat in batch) {
      _loadChatUsers(chat);
    }
  }

  // Add this method to load more chats
  void loadMoreChats() {
    if (!hasMoreChats.value || isLoading.value) return;
    isLoading.value = true;

    _loadNextChatBatch();

    isLoading.value = false;
  }

  // Modify the _loadChatUsers method to start listening to status
  Future<void> _loadChatUsers(ChatModel chat) async {
    for (final userId in chat.participants) {
      if (userId != _authService.firebaseUser.value?.uid) {
        // Load user info
        final userInfo = await _chatService.getUserInfo(userId);
        if (userInfo != null) {
          chatUsers[userId] = userInfo;
          userOnlineStatus[userId] = userInfo.isOnline;
          userLastSeen[userId] = userInfo.lastSeen;

          // Start listening to status changes
          listenToUserStatus(userId);
        }
      }
    }
  }

  // Search for a user by email
  Future<void> searchUserByEmail(String email) async {
    if (email.isEmpty) {
      searchedUser.value = null;
      return;
    }

    isSearching.value = true;

    try {
      // Don't search for current user's email
      if (_authService.userModel.value?.email == email) {
        Get.snackbar('Error', 'You cannot chat with yourself');
        searchedUser.value = null;
        return;
      }

      final user = await _chatService.searchUserByEmail(email);
      searchedUser.value = user;

      if (user == null) {
        Get.snackbar('User Not Found', 'No user found with this email');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to search for user');
      print('Search error: $e');
    } finally {
      isSearching.value = false;
    }
  }

  // Create a new chat or get existing chat
  Future<void> createOrGetChatWithUser(String userId) async {
    isLoading.value = true;

    try {
      final chat = await _chatService.createOrGetChat(userId);

      if (chat != null) {
        selectedChatId.value = chat.id;
        loadChatMessages(chat.id);

        if (!userChats.any((c) => c.id == chat.id)) {
          userChats.add(chat);
        }

        searchedUser.value = null; // Clear search state

        // Close search screen and navigate to chat
        Get.until((route) => route.isFirst); // Return to home
        Get.toNamed('/chat/${chat.id}');
      } else {
        Get.snackbar('Error', 'Failed to create chat');
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred');
      print('Create chat error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Load messages for a specific chat

  void loadChatMessagesWithAutoRead(String chatId) {
    isLoadingMessages.value = true;
    selectedChatId.value = chatId;

    // Get the chat to find the other user's ID
    final matches = userChats.where((c) => c.id == chatId).toList();
    final ChatModel? chat = matches.isNotEmpty ? matches.first : null;

    if (chat != null) {
      final otherUserId = chat.participants.firstWhere(
        (id) => id != _authService.firebaseUser.value?.uid,
        orElse: () => '',
      );

      // Mark messages from other user as delivered when opening the chat
      if (otherUserId.isNotEmpty) {
        _chatService.markMessagesAsDelivered(chatId, otherUserId);
      }
    }

    // Mark chat as read
    _chatService.markChatAsRead(chatId);

    // Subscribe to messages stream
    _chatService.getChatMessages(chatId).listen((messages) {
      currentChatMessages.value = messages;
      isLoadingMessages.value = false;
    });
  }

  // Send a message
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || selectedChatId.value.isEmpty) return;

    try {
      await _chatService.sendMessage(selectedChatId.value, text.trim());
    } catch (e) {
      Get.snackbar('Error', 'Failed to send message');
      print('Send message error: $e');
    }
  }

  // Clear selection when exiting a chat
  void clearSelectedChat() {
    selectedChatId.value = '';
    currentChatMessages.clear();
    searchedUser.value = null; // Also clear search state
  }

  // Hide chat from current user's list
  Future<void> hideChat(String chatId) async {
    await ChatService.instance.hideChatForUser(chatId);
  }

  // Unhide chat (not exposed in UI yet)
  Future<void> unhideChat(String chatId) async {
    await ChatService.instance.unhideChatForUser(chatId);
  }

  // Clear only my messages in a chat
  Future<void> clearMyMessages(String chatId) async {
    await ChatService.instance.clearMyMessagesFromChat(chatId);
  }

  // Delete the entire chat for everyone
  Future<void> deleteChatForEveryone(String chatId) async {
    await ChatService.instance.deleteChatForEveryone(chatId);
    // Remove locally if present
    userChats.removeWhere((c) => c.id == chatId);
    if (selectedChatId.value == chatId) {
      clearSelectedChat();
    }
  }

  // Add to ChatController class
  final RxMap<String, bool> userOnlineStatus = <String, bool>{}.obs;
  final RxMap<String, DateTime?> userLastSeen = <String, DateTime?>{}.obs;

  void listenToUserStatus(String userId) {
    if (userId.isEmpty) return;

    // Don't create duplicate subscriptions
    if (_statusSubscriptions.containsKey(userId)) {
      return;
    }

    // Listen to changes in the user's status
    final subscription = _chatService.listenToUserOnlineStatus(userId).listen((
      userData,
    ) {
      if (userData != null) {
        // Update our maps with the properly filtered status from the service
        userOnlineStatus[userId] = userData.isOnline;
        userLastSeen[userId] = userData.lastSeen;
      }
    });

    // Store the subscription
    _statusSubscriptions[userId] = subscription;
  }

  // Get chat partner's name for display
  String getChatName(ChatModel chat) {
    final otherUserId = chat.participants.firstWhere(
      (id) => id != _authService.firebaseUser.value?.uid,
      orElse: () => 'Unknown',
    );

    return chatUsers[otherUserId]?.fullName ?? 'Unknown User';
  }

  // Get chat partner's profile picture
  String? getChatProfilePic(ChatModel chat) {
    final otherUserId = chat.participants.firstWhere(
      (id) => id != _authService.firebaseUser.value?.uid,
      orElse: () => '',
    );

    return chatUsers[otherUserId]?.profilePicUrl;
  }

  // Get unread message count for a chat
  int getUnreadCount(ChatModel chat) {
    final userId = _authService.firebaseUser.value?.uid;
    if (userId == null) return 0;

    return chat.unreadCount[userId] ?? 0;
  }

  @override
  void onClose() {
    _messagesSubscription?.cancel();

    // Cancel all status subscriptions
    for (final subscription in _statusSubscriptions.values) {
      subscription.cancel();
    }
    _statusSubscriptions.clear();

    selectedChatId.value = '';
    currentChatMessages.clear();
    super.onClose();
  }

  // Add to ChatController class
  void refreshChats() {
    print("Manually refreshing chats for user: ${currentUser?.id}");
    userChats.clear();
    chatUsers.clear();
    _listenToUserChats();
  }

  // Add to ChatController class properties
  StreamSubscription<List<MessageModel>>? _messagesSubscription;

  // Modify the loadChatMessages method
  void loadChatMessages(String chatId) {
    isLoadingMessages.value = true;
    selectedChatId.value = chatId;

    // Get the chat to find the other user's ID
    final matches = userChats.where((c) => c.id == chatId).toList();
    final ChatModel? chat = matches.isNotEmpty ? matches.first : null;

    if (chat != null) {
      final otherUserId = chat.participants.firstWhere(
        (id) => id != _authService.firebaseUser.value?.uid,
        orElse: () => '',
      );

      // Mark messages from other user as delivered when opening the chat
      if (otherUserId.isNotEmpty) {
        _chatService.markMessagesAsDelivered(chatId, otherUserId);
      }
    }

    // Mark chat as read initially
    _chatService.markChatAsRead(chatId);

    // Cancel any existing subscription
    _messagesSubscription?.cancel();

    // Subscribe to messages stream with auto-read functionality
    _messagesSubscription = _chatService.getChatMessages(chatId).listen((
      messages,
    ) {
      currentChatMessages.value = messages;
      isLoadingMessages.value = false;

      // If we're in the chat and there are unread messages from other users, mark them as read
      if (selectedChatId.value == chatId) {
        _markNewMessagesAsRead(messages, chatId);
      }
    });
  }

  // Add this new method to mark new messages as read
  void _markNewMessagesAsRead(List<MessageModel> messages, String chatId) {
    final userId = _authService.firebaseUser.value?.uid;
    if (userId == null) return;

    // Check if there are any unread messages from other users
    final hasUnreadMessages = messages.any(
      (msg) => msg.senderId != userId && !msg.isRead,
    );

    if (hasUnreadMessages) {
      // Mark them as read
      _chatService.markChatAsRead(chatId);
    }
  }

  // Add the suggested method
  void markCurrentChatMessagesAsRead() {
    if (selectedChatId.value.isNotEmpty) {
      _chatService.markChatAsRead(selectedChatId.value);
    }
  }

  Future<void> markChatAsRead(String chatId) async {
    await _chatService.markChatAsRead(chatId);
  }

  // Use this in the UI to determine if we should show the online indicator
  bool shouldShowOnlineIndicator(String userId) {
    // Get the user's showOnlineStatus preference
    final targetUserModel = chatUsers[userId];
    if (targetUserModel == null) return false;

    // Only show if both users have enabled status sharing
    return targetUserModel.showOnlineStatus &&
        (_authService.userModel.value?.showOnlineStatus ?? false) &&
        (userOnlineStatus[userId] ?? false);
  }

  // Get appropriate last seen text based on privacy settings
  String getLastSeenText(String userId) {
    final targetUserModel = chatUsers[userId];
    if (targetUserModel == null) return "Offline";

    // If either user has disabled status sharing, just show "Offline"
    if (!targetUserModel.showOnlineStatus ||
        !(_authService.userModel.value?.showOnlineStatus ?? false)) {
      return "Offline";
    }

    // User is online
    if (userOnlineStatus[userId] == true) {
      return "Online";
    }

    // User is offline but we can show last seen
    final lastSeen = userLastSeen[userId];
    if (lastSeen != null) {
      // Format the lastSeen timestamp appropriately
      return "Last seen ${_formatLastSeen(lastSeen)}";
    }

    return "Offline";
  }

  // Helper to format last seen time
  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return "just now";
    } else if (difference.inHours < 1) {
      return "${difference.inMinutes} min ago";
    } else if (difference.inDays < 1) {
      return "${difference.inHours} hours ago";
    } else if (difference.inDays < 7) {
      return "${difference.inDays} days ago";
    } else {
      // Format as date for older timestamps
      return "${lastSeen.day}/${lastSeen.month}/${lastSeen.year}";
    }
  }

  // Edit a message
  Future<void> editMessage(
    String chatId,
    String messageId,
    String newText,
  ) async {
    await _chatService.editMessage(
      chatId: chatId,
      messageId: messageId,
      newText: newText.trim(),
    );
  }

  // Delete a message (soft delete)
  Future<void> deleteMessage(String chatId, String messageId) async {
    await _chatService.deleteMessage(chatId: chatId, messageId: messageId);
  }

  // Clear all messages in a chat for both users (dangerous). Here we just mark all as deleted.
  Future<void> clearChat(String chatId) async {
    // Mark all messages as deleted for a chat
    try {
      final messages =
          await ChatService.instance
              .getChatMessages(chatId)
              .first; // one-time read
      for (final m in messages) {
        if (m.senderId == currentUser?.id) {
          await deleteMessage(chatId, m.id);
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to clear chat');
    }
  }

  // Get other user's model for a chat
  UserModel? getOtherUser(String chatId) {
    final matches = userChats.where((c) => c.id == chatId).toList();
    if (matches.isEmpty) return null;
    final chat = matches.first;
    final currentId = _authService.userModel.value?.id;
    final otherId = chat.participants.firstWhere(
      (id) => id != currentId,
      orElse: () => '',
    );
    if (otherId.isEmpty) return null;
    return chatUsers[otherId];
  }
}
