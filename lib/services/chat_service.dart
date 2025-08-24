import 'package:cloud_firestore/cloud_firestore.dart';
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
  final CollectionReference _chatsCollection = FirebaseFirestore.instance
      .collection('chats');
  final CollectionReference _usersCollection = FirebaseFirestore.instance
      .collection('users');

  // Get current user ID
  String? get currentUserId => _authService.firebaseUser.value?.uid;

  // Search user by email
  Future<UserModel?> searchUserByEmail(String email) async {
    try {
      final querySnapshot =
          await _usersCollection
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

  Stream<UserModel?> listenToUserOnlineStatus(String userId) {
    return _usersCollection.doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      try {
        UserModel user = UserModel.fromMap(
          snapshot.data() as Map<String, dynamic>,
        );

        // Get the current user's showOnlineStatus
        // Respect privacy: if the target user hides their status, surface offline

        // If the target user hides their status, show them as offline with no last seen
        if (!user.showOnlineStatus) {
          return user.copyWith(isOnline: false, lastSeen: null);
        }

        // Return actual status since both users allow sharing status
        return user;
      } catch (e) {
        print('Error parsing user data: $e');
        return null;
      }
    });
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
      final existingChat = await findChatBetweenUsers(
        currentUserId!,
        otherUserId,
      );
      if (existingChat != null) {
        return existingChat;
      }

      // Create a new chat
      final participants = [currentUserId!, otherUserId];
      final chatData = ChatModel(
        id: '', // Will be set after document creation
        participants: participants,
        createdAt: DateTime.now(),
        unreadCount: {currentUserId!: 0, otherUserId: 0},
      );

      final docRef = await _chatsCollection.add(chatData.toMap());
      final createdChat = await docRef.get();
      if (createdChat.exists) {
        return ChatModel.fromMap(
          createdChat.data() as Map<String, dynamic>,
          docRef.id,
        );
      } else {
        throw Exception('Failed to create chat');
      }
    } catch (e) {
      print('Error creating chat: $e');
      return null; // Return null if chat creation fails
    }
  }

  // Find an existing chat between two users
  Future<ChatModel?> findChatBetweenUsers(
    String userId1,
    String userId2,
  ) async {
    try {
      final querySnapshot =
          await _chatsCollection
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

            final list =
                snapshot.docs.map((doc) {
                  // Add logging to help debug
                  print('Processing chat: ${doc.id}');
                  final data = doc.data() as Map<String, dynamic>;
                  return ChatModel.fromMap(data, doc.id);
                }).toList();

            // Filter out chats hidden by current user
            return list
                .where((c) => (c.hiddenBy[currentUserId!] ?? false) == false)
                .toList();
          } catch (e) {
            print('Error processing chat documents: $e');
            return [];
          }
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
            return MessageModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Hide chat for the current user (soft delete from list)
  Future<void> hideChatForUser(String chatId) async {
    if (currentUserId == null) return;
    await _chatsCollection.doc(chatId).set({
      'hiddenBy': {currentUserId!: true},
    }, SetOptions(merge: true));
  }

  // Unhide chat for the current user
  Future<void> unhideChatForUser(String chatId) async {
    if (currentUserId == null) return;
    await _chatsCollection.doc(chatId).set({
      'hiddenBy': {currentUserId!: false},
    }, SetOptions(merge: true));
  }

  // Clear my messages from a chat (soft-delete my messages only)
  Future<void> clearMyMessagesFromChat(String chatId) async {
    if (currentUserId == null) return;
    final batch = _db.batch();
    final msgs =
        await _chatsCollection
            .doc(chatId)
            .collection('messages')
            .where('senderId', isEqualTo: currentUserId)
            .get();
    for (final doc in msgs.docs) {
      batch.update(doc.reference, {
        'isDeleted': true,
        'text': '',
        'deletedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // Optionally delete chat if no messages remain (hard delete)
  Future<void> deleteChatIfEmpty(String chatId) async {
    final messages =
        await _chatsCollection
            .doc(chatId)
            .collection('messages')
            .limit(1)
            .get();
    if (messages.docs.isEmpty) {
      await _chatsCollection.doc(chatId).delete();
    }
  }

  // Delete the entire chat for everyone (dangerous, irreversible)
  Future<void> deleteChatForEveryone(String chatId) async {
    if (currentUserId == null) return;

    // Ensure the requester is a participant
    final chatDoc = await _chatsCollection.doc(chatId).get();
    if (!chatDoc.exists) return;
    final data = chatDoc.data() as Map<String, dynamic>;
    final participants = List<String>.from(data['participants'] ?? []);
    if (!participants.contains(currentUserId)) {
      throw Exception('Not authorized to delete this chat');
    }

    // Delete messages in batches to avoid batch size limits
    const int pageSize = 300;
    while (true) {
      final snap =
          await _chatsCollection
              .doc(chatId)
              .collection('messages')
              .limit(pageSize)
              .get();
      if (snap.docs.isEmpty) break;

      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    // Delete the chat document
    await _chatsCollection.doc(chatId).delete();
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
      await _chatsCollection
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

  // Edit an existing message (only by sender)
  Future<void> editMessage({
    required String chatId,
    required String messageId,
    required String newText,
  }) async {
    if (currentUserId == null) throw Exception('Not authenticated');

    final msgRef = _chatsCollection
        .doc(chatId)
        .collection('messages')
        .doc(messageId);
    final msgSnap = await msgRef.get();
    if (!msgSnap.exists) throw Exception('Message not found');

    final data = msgSnap.data() as Map<String, dynamic>;
    if (data['senderId'] != currentUserId) {
      throw Exception('Only the sender can edit this message');
    }

    await msgRef.update({
      'text': newText,
      'isEdited': true,
      'editedAt': FieldValue.serverTimestamp(),
    });

    // If this is the last message, update chat preview
    final chatDoc = await _chatsCollection.doc(chatId).get();
    final chatData = chatDoc.data() as Map<String, dynamic>;
    if ((chatData['lastMessageSenderId'] ?? '') == currentUserId) {
      await _chatsCollection.doc(chatId).update({'lastMessageText': newText});
    }
  }

  // Soft delete a message (only by sender)
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    if (currentUserId == null) throw Exception('Not authenticated');
    final msgRef = _chatsCollection
        .doc(chatId)
        .collection('messages')
        .doc(messageId);
    final msgSnap = await msgRef.get();
    if (!msgSnap.exists) return;

    final data = msgSnap.data() as Map<String, dynamic>;
    if (data['senderId'] != currentUserId) {
      throw Exception('Only the sender can delete this message');
    }

    await msgRef.update({
      'isDeleted': true,
      'text': '',
      'deletedAt': FieldValue.serverTimestamp(),
    });

    // If it was the last message, update chat preview
    final chatDoc = await _chatsCollection.doc(chatId).get();
    final chatData = chatDoc.data() as Map<String, dynamic>;
    if ((chatData['lastMessageSenderId'] ?? '') == currentUserId) {
      await _chatsCollection.doc(chatId).update({
        'lastMessageText': 'Message deleted',
      });
    }
  }

  // Add this new method to mark messages as delivered
  Future<void> markMessagesAsDelivered(String chatId, String senderId) async {
    try {
      if (currentUserId == null) return;

      // Only mark other user's messages as delivered
      if (currentUserId == senderId) return;

      final batch = _db.batch();
      final messagesSnapshot =
          await _chatsCollection
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
      await _chatsCollection.doc(chatId).update({'unreadCount': unreadCount});

      // Only query messages that are actually unread
      final messagesSnapshot =
          await _chatsCollection
              .doc(chatId)
              .collection('messages')
              .where('senderId', isNotEqualTo: currentUserId)
              .where('isRead', isEqualTo: false)
              .get();

      if (messagesSnapshot.docs.isNotEmpty) {
        final batch = _db.batch();

        for (final doc in messagesSnapshot.docs) {
          batch.update(doc.reference, {'isRead': true});
        }

        await batch.commit();
      }
    } catch (e) {
      print('Error marking chat as read: $e');
    }
  }

  // Get user info for chat participants
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
