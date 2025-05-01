// lib/models/message_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final DateTime sentAt;
  final bool isRead;
  final bool isDelivered; // Add this field
  final Map<String, dynamic>? metadata;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.sentAt,
    required this.isRead,
    this.isDelivered = false, // Default to false
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'sentAt': sentAt,
      'isRead': isRead,
      'isDelivered': isDelivered,
      'metadata': metadata,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, String documentId) {
    return MessageModel(
      id: documentId,
      chatId: map['chatId'],
      senderId: map['senderId'],
      text: map['text'],
      sentAt: (map['sentAt'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
      isDelivered: map['isDelivered'] ?? false,
      metadata: map['metadata'],
    );
  }
}