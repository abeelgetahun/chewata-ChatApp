import 'dart:async';
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

  // Deterministic key for a user pair to ensure single chat per pair
  String _pairKey(String a, String b) {
    final list = [a, b]..sort();
    return '${list[0]}_${list[1]}';
  }

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

  // New: Search users by email prefix and name prefix (as-you-type)
  Future<List<UserModel>> searchUsers({
    required String query,
    int limit = 20,
  }) async {
    try {
      final q = query.trim();
      if (q.isEmpty) return [];

      final String qLower = q.toLowerCase();

      // Email prefix search (emails are usually stored lowercase)
      final emailSnap =
          await _usersCollection
              .orderBy('email')
              .startAt([qLower])
              .endAt([qLower + '\uf8ff'])
              .limit(limit)
              .get();

      // Name prefix search. Firestore is case-sensitive, so try both raw and capitalized variants
      String capitalize(String s) =>
          s.isEmpty
              ? s
              : s[0].toUpperCase() + (s.length > 1 ? s.substring(1) : '');

      final qCap = capitalize(q);

      final nameSnap1 =
          await _usersCollection
              .orderBy('fullName')
              .startAt([q])
              .endAt([q + '\uf8ff'])
              .limit(limit)
              .get();

      // If the raw-case query yields little due to case, try capitalized
      final nameSnap2 =
          qCap == q
              ? null
              : await _usersCollection
                  .orderBy('fullName')
                  .startAt([qCap])
                  .endAt([qCap + '\uf8ff'])
                  .limit(limit)
                  .get();

      final Map<String, UserModel> merged = {};

      void addFrom(QuerySnapshot snap) {
        for (final doc in snap.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final user = UserModel.fromMap(data);
          if (user.id != currentUserId) {
            merged[user.id] = user;
          }
        }
      }

      addFrom(emailSnap);
      addFrom(nameSnap1);
      if (nameSnap2 != null) addFrom(nameSnap2);

      // Optional post-filtering to be a bit more forgiving (case-insensitive contains)
      final List<UserModel> results =
          merged.values
              .where(
                (u) =>
                    u.email.toLowerCase().startsWith(qLower) ||
                    u.fullName.toLowerCase().startsWith(qLower),
              )
              .take(limit)
              .toList();

      return results;
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  Stream<UserModel?> listenToUserOnlineStatus(String userId) {
    return _usersCollection.doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      try {
        UserModel user = UserModel.fromMap(
          snapshot.data() as Map<String, dynamic>,
        );

        // Respect privacy in both directions:
        // 1) If the target user hides their status, expose them as offline (no lastSeen)
        if (!user.showOnlineStatus) {
          return user.copyWith(isOnline: false, lastSeen: null);
        }

        // 2) If the current viewer has disabled their own status visibility,
        //    they should NOT be able to see others' status either.
        final bool viewerAllowsStatus =
            _authService.userModel.value?.showOnlineStatus ?? true;
        if (!viewerAllowsStatus) {
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

      // Check if chat already exists using unified finder (pairKey first, then participants)
      final pairKey = _pairKey(currentUserId!, otherUserId);
      final existingChat = await findChatBetweenUsers(
        currentUserId!,
        otherUserId,
      );
      if (existingChat != null) {
        // Ensure pairKey is set on legacy chats
        try {
          await _chatsCollection.doc(existingChat.id).set({
            'pairKey': pairKey,
          }, SetOptions(merge: true));
        } catch (_) {}
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

      final data = chatData.toMap();
      data['pairKey'] = pairKey;
      final docRef = await _chatsCollection.add(data);
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
      final pairKey = _pairKey(userId1, userId2);
      // 1) Try by pairKey (new schema)
      final byKey =
          await _chatsCollection
              .where('pairKey', isEqualTo: pairKey)
              .limit(1)
              .get();
      if (byKey.docs.isNotEmpty) {
        final doc = byKey.docs.first;
        return ChatModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }

      // 2) Fallback for legacy chats without pairKey: scan by participants
      final byPart =
          await _chatsCollection
              .where('participants', arrayContains: userId1)
              .get();
      for (final doc in byPart.docs) {
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

  // Get messages for a specific chat (merge subcollection and legacy top-level messages)
  Stream<List<MessageModel>> getChatMessages(String chatId) {
    final subcollectionStream =
        _chatsCollection
            .doc(chatId)
            .collection('messages')
            .orderBy('sentAt', descending: true)
            .snapshots();

    // Legacy: some older code stored messages in a top-level collection
    final topLevelStream =
        _db
            .collection('messages')
            .where('chatId', isEqualTo: chatId)
            .orderBy('sentAt', descending: true)
            .snapshots();

    // Merge both streams manually to avoid extra deps
    final controller = StreamController<List<MessageModel>>();
    List<MessageModel> subMsgs = [];
    List<MessageModel> topMsgs = [];
    StreamSubscription? subA;
    StreamSubscription? subB;

    void emit() {
      final all = <MessageModel>[...subMsgs, ...topMsgs];
      all.sort((a, b) => b.sentAt.compareTo(a.sentAt));
      controller.add(all);
    }

    subA = subcollectionStream.listen((snapshot) {
      final tmp = <MessageModel>[];
      for (final doc in snapshot.docs) {
        try {
          tmp.add(MessageModel.fromMap(doc.data(), doc.id));
        } catch (e) {
          print('Skipping malformed subcollection message ${doc.id}: $e');
        }
      }
      subMsgs = tmp;
      emit();
    }, onError: controller.addError);

    subB = topLevelStream.listen((snapshot) {
      final tmp = <MessageModel>[];
      for (final doc in snapshot.docs) {
        try {
          tmp.add(MessageModel.fromMap(doc.data(), doc.id));
        } catch (e) {
          print('Skipping malformed top-level message ${doc.id}: $e');
        }
      }
      topMsgs = tmp;
      emit();
    }, onError: controller.addError);

    controller.onCancel = () async {
      await subA?.cancel();
      await subB?.cancel();
    };

    return controller.stream;
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

      // Also update legacy top-level messages
      final legacySnap =
          await _db
              .collection('messages')
              .where('chatId', isEqualTo: chatId)
              .where('senderId', isEqualTo: senderId)
              .where('isDelivered', isEqualTo: false)
              .get();
      for (final doc in legacySnap.docs) {
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
        // Also mark legacy top-level messages as read
        final legacySnap =
            await _db
                .collection('messages')
                .where('chatId', isEqualTo: chatId)
                .where('senderId', isNotEqualTo: currentUserId)
                .where('isRead', isEqualTo: false)
                .get();
        for (final doc in legacySnap.docs) {
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
      UserModel user = UserModel.fromMap(data);

      // Apply the same privacy reciprocity used in the stream
      if (!user.showOnlineStatus) {
        return user.copyWith(isOnline: false, lastSeen: null);
      }

      final bool viewerAllowsStatus =
          _authService.userModel.value?.showOnlineStatus ?? true;
      if (!viewerAllowsStatus) {
        return user.copyWith(isOnline: false, lastSeen: null);
      }

      return user;
    } catch (e) {
      print('Error getting user info: $e');
      return null;
    }
  }
}
