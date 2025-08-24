import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participants; // User IDs of chat participants
  final DateTime createdAt;
  final DateTime? lastMessageTime;
  final String? lastMessageText;
  final String? lastMessageSenderId;
  final Map<String, int> unreadCount; // Map of userId -> unread count
  final Map<String, bool> hiddenBy; // Map of userId -> hidden

  ChatModel({
    required this.id,
    required this.participants,
    required this.createdAt,
    this.lastMessageTime,
    this.lastMessageText,
    this.lastMessageSenderId,
    required this.unreadCount,
    this.hiddenBy = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'createdAt': createdAt,
      'lastMessageTime': lastMessageTime,
      'lastMessageText': lastMessageText,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'hiddenBy': hiddenBy,
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map, String documentId) {
    try {
      return ChatModel(
        id: documentId,
        participants: List<String>.from(map['participants'] ?? []),
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        lastMessageTime:
            map['lastMessageTime'] != null
                ? (map['lastMessageTime'] as Timestamp).toDate()
                : null,
        lastMessageText: map['lastMessageText'],
        lastMessageSenderId: map['lastMessageSenderId'],
        unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
        hiddenBy: Map<String, bool>.from(map['hiddenBy'] ?? {}),
      );
    } catch (e) {
      print('Error parsing ChatModel from map: $e');
      // Return a fallback model
      return ChatModel(
        id: documentId,
        participants: [],
        createdAt: DateTime.now(),
        unreadCount: {},
      );
    }
  }
}
