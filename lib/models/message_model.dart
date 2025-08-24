 
import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final DateTime sentAt;
  final bool isRead;
  final bool isDelivered; // delivery/seen indicators
  final bool isDeleted; // soft delete flag
  final bool isEdited; // edited flag
  final DateTime? editedAt;
  final DateTime? deletedAt;
  final Map<String, dynamic>? metadata;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.sentAt,
    required this.isRead,
    this.isDelivered = false,
    this.isDeleted = false,
    this.isEdited = false,
    this.editedAt,
    this.deletedAt,
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
      'isDeleted': isDeleted,
      'isEdited': isEdited,
      'editedAt': editedAt,
      'deletedAt': deletedAt,
      'metadata': metadata,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime? _tsToDate(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return MessageModel(
      id: documentId,
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      sentAt: (map['sentAt'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
      isDelivered: map['isDelivered'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
      isEdited: map['isEdited'] ?? false,
      editedAt: _tsToDate(map['editedAt']),
      deletedAt: _tsToDate(map['deletedAt']),
      metadata: map['metadata'],
    );
  }
}
