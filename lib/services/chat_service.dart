import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:chewata/models/chat_model.dart';
import 'package:chewata/models/message_model.dart';
import 'package:chewata/models/user_model.dart';
import 'package:chewata/services/auth_service.dart';

class ChatService extends GetxService {
  static ChatService get instance => Get.find();
  
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService.instance;
  
  // Collection references
  final CollectionReference _chatsCollection = 
      FirebaseFirestore.instance.collection('chats');
  final CollectionReference _usersCollection = 
      FirebaseFirestore.instance.collection('users');
  
  // Get current user ID
  String? get currentUserId => _authService.firebaseUser.value?.uid;
  
  // Search user by email
  Future<UserModel?> searchUserByEmail(String email) async {
    try {
      final querySnapshot = await _usersCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        return null;
      }
      
      final userData = querySnapshot.docs.first.data() as Map<String, dynamic>;
      return UserModel.fromMap(userData);
    } catch (e) {
      print('Error searching user: $e');
      return null;
    }
  }
  
  // Create a new chat or get existing chat between two users
  Future<ChatModel?> createOrGetChat(String otherUserId) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      if (currentUserId == otherUserId) {
        throw Exception('Cannot create chat with yourself');
      }

      // Check if chat already exists
      final existingChat = await findChatBetweenUsers(currentUserId!, otherUserId);
      if (existingChat != null) {
        return existingChat;
      }

      // Create a new chat
      final participants = [currentUserId!, otherUserId];
      final chatData = ChatModel(
        id: '', // Will be set after document creation
        participants: participants,
        createdAt: DateTime.now(),
        unreadCount: {
          currentUserId!: 0,
          otherUserId: 0,
        },
      );

      final docRef = await _chatsCollection.add(chatData.toMap());
      final createdChat = await docRef.get();
      if (createdChat.exists) {
        return ChatModel.fromMap(createdChat.data() as Map<String, dynamic>, docRef.id);
      } else {
        throw Exception('Failed to create chat');
      }
    } catch (e) {
      print('Error creating chat: $e');
      return null; // Return null if chat creation fails
    }
  }
  
  // Find an existing chat between two users
  Future<ChatModel?> findChatBetweenUsers(String userId1, String userId2) async {
    try {
      final querySnapshot = await _chatsCollection
          .where('participants', arrayContains: userId1)
          .get();
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final participants = List<String>.from(data['participants'] ?? []);
        
        if (participants.contains(userId2)) {
          return ChatModel.fromMap(data, doc.id);
        }
      }
      
      return null;
    } catch (e) {
      print('Error finding chat: $e');
      return null;
    }
  }
  
  // Get all chats for current user
  Stream<List<ChatModel>> getUserChats() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _chatsCollection
        .where('participants', arrayContains: currentUserId!)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
          try {
            if (snapshot.docs.isEmpty) {
              print('No chats found for user $currentUserId');
              return [];
            }
            
            return snapshot.docs.map((doc) {
              // Add logging to help debug
              print('Processing chat: ${doc.id}');
              final data = doc.data() as Map<String, dynamic>;
              return ChatModel.fromMap(data, doc.id);
            }).toList();
          } catch (e) {
            print('Error processing chat documents: $e');
            return [];
          }
        });
  }

  // Method to listen to a user's online status
  Stream<UserModel?> listenToUserOnlineStatus(String userId) {
    return _usersCollection.doc(userId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return null;
          return UserModel.fromMap(snapshot.data() as Map<String, dynamic>);
        });
  }
  
  // Get messages for a specific chat
  Stream<List<MessageModel>> getChatMessages(String chatId) {
    return _chatsCollection
        .doc(chatId)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MessageModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id
            );
          }).toList();
        });
  }
  
  // Send a message
  // In chat_service.dart, modify the sendMessage method
  Future<bool> sendMessage(String chatId, String text) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }
      
      final chatDoc = await _chatsCollection.doc(chatId).get();
      if (!chatDoc.exists) {
        throw Exception('Chat does not exist');
      }
      
      final chatData = chatDoc.data() as Map<String, dynamic>;
      final participants = List<String>.from(chatData['participants'] ?? []);
      
      if (!participants.contains(currentUserId)) {
        throw Exception('User not in this chat');
      }
      
      // Create message
      final message = MessageModel(
        id: '',
        chatId: chatId,
        senderId: currentUserId!,
        text: text,
        sentAt: DateTime.now(),
        isRead: false,
        isDelivered: false, // Initialize as not delivered
      );
      
      // Add message to subcollection
      final messageRef = await _chatsCollection
          .doc(chatId)
          .collection('messages')
          .add(message.toMap());
      
      // Update chat with last message info
      final unreadCount = Map<String, int>.from(chatData['unreadCount'] ?? {});
      
      // Increment unread count for all participants except sender
      for (final participant in participants) {
        if (participant != currentUserId) {
          unreadCount[participant] = (unreadCount[participant] ?? 0) + 1;
        }
      }
      
      await _chatsCollection.doc(chatId).update({
        'lastMessageText': text,
        'lastMessageTime': message.sentAt,
        'lastMessageSenderId': currentUserId,
        'unreadCount': unreadCount,
      });
      
      return true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  // Add this new method to mark messages as delivered
  Future<void> markMessagesAsDelivered(String chatId, String senderId) async {
    try {
      if (currentUserId == null) return;
      
      // Only mark other user's messages as delivered
      if (currentUserId == senderId) return;
      
      final batch = _db.batch();
      final messagesSnapshot = await _chatsCollection
          .doc(chatId)
          .collection('messages')
          .where('senderId', isEqualTo: senderId)
          .where('isDelivered', isEqualTo: false)
          .get();
      
      for (final doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {'isDelivered': true});
      }
      
      await batch.commit();
    } catch (e) {
      print('Error marking messages as delivered: $e');
    }
  }

  // Modify the markChatAsRead method
  // Improve the markChatAsRead method in ChatService class
Future<void> markChatAsRead(String chatId) async {
  try {
    if (currentUserId == null) return;

    // Get chat document
    final chatDoc = await _chatsCollection.doc(chatId).get();
    if (!chatDoc.exists) return;

    final chatData = chatDoc.data() as Map<String, dynamic>;
    final unreadCount = Map<String, int>.from(chatData['unreadCount'] ?? {});

    // If no unread messages for current user, no need to update
    if ((unreadCount[currentUserId!] ?? 0) == 0) return;

    // Reset unread count for current user
    unreadCount[currentUserId!] = 0;

    // Update chat document
    await _chatsCollection.doc(chatId).update({
      'unreadCount': unreadCount,
    });

    // Only query messages that are actually unread
    final messagesSnapshot = await _chatsCollection
        .doc(chatId)
        .collection('messages')
        .where('senderId', isNotEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    if (messagesSnapshot.docs.isNotEmpty) {
      final batch = _db.batch();
      
      for (final doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
        });
      }

      await batch.commit();
    }
  } catch (e) {
    print('Error marking chat as read: $e');
  }
}

 // Get user info for chat participants
  // In chat_service.dart, modify the getUserInfo method

  Future<UserModel?> getUserInfo(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (!doc.exists) return null;
      
      final data = doc.data() as Map<String, dynamic>;
      
      // Include online status in user info
      return UserModel.fromMap(data);
    } catch (e) {
      print('Error getting user info: $e');
      return null;
    }
  }
}