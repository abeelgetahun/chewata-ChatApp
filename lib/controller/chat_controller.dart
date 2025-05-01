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
    _chatService.getUserChats().listen((chats) {
      userChats.value = chats;

      // Load user info for each chat participant
      for (final chat in chats) {
        _loadChatUsers(chat);
      }
    });
  }
  
  // Load user information for chat participants
  Future<void> _loadChatUsers(ChatModel chat) async {
    for (final userId in chat.participants) {
      if (!chatUsers.containsKey(userId) && userId != _authService.firebaseUser.value?.uid) {
        final userInfo = await _chatService.getUserInfo(userId);
        if (userInfo != null) {
          chatUsers[userId] = userInfo;
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
        // Select the chat and load messages
        selectedChatId.value = chat.id;
        loadChatMessages(chat.id);
        
        // If it's a new chat, add it to the list
        if (!userChats.any((c) => c.id == chat.id)) {
          userChats.add(chat);
        }
        
        // Clear searched user
        searchedUser.value = null;
        
        // Navigate to chat screen
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
    
  void loadChatMessages(String chatId) {
    isLoadingMessages.value = true;
    selectedChatId.value = chatId;
    
    // Get the chat to find the other user's ID
    final chat = userChats.firstWhere(
      (c) => c.id == chatId,
      orElse: () => null as dynamic,
    );
    
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
}