
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participants; // User IDs of chat participants
  final DateTime createdAt;
  final DateTime? lastMessageTime;
  final String? lastMessageText;
  final String? lastMessageSenderId;
  final Map<String, int> unreadCount; // Map of userId -> unread count

  ChatModel({
    required this.id,
    required this.participants,
    required this.createdAt,
    this.lastMessageTime,
    this.lastMessageText,
    this.lastMessageSenderId,
    required this.unreadCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'createdAt': createdAt,
      'lastMessageTime': lastMessageTime,
      'lastMessageText': lastMessageText,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ChatModel(
      id: documentId,
      participants: List<String>.from(map['participants'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastMessageTime: map['lastMessageTime'] != null 
          ? (map['lastMessageTime'] as Timestamp).toDate() 
          : null,
      lastMessageText: map['lastMessageText'],
      lastMessageSenderId: map['lastMessageSenderId'],
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
    );
  }
}