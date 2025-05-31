class ChatHistory {
  final String id;
  final String message;
  final String sender;
  final String receiver;
  final DateTime timestamp;
  final bool isRead;

  ChatHistory({
    required this.id,
    required this.message,
    required this.sender,
    required this.receiver,
    required this.timestamp,
    this.isRead = false,
  });

  // Convert ChatHistory object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'sender': sender,
      'receiver': receiver,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  // Create ChatHistory object from JSON
  factory ChatHistory.fromJson(Map<String, dynamic> json) {
    return ChatHistory(
      id: json['id'],
      message: json['message'],
      sender: json['sender'],
      receiver: json['receiver'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
    );
  }

  // Format timestamp for display
  String getFormattedTimestamp() {
    return "${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}";
  }
}