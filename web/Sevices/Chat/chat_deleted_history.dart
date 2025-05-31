class ChatDeletedHistory {
  final String messageId;
  final String deletedBy;
  final DateTime deletedAt;

  ChatDeletedHistory({
    required this.messageId,
    required this.deletedBy,
    required this.deletedAt,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'deletedBy': deletedBy,
      'deletedAt': deletedAt.toIso8601String(),
    };
  }

  // Create from JSON
  factory ChatDeletedHistory.fromJson(Map<String, dynamic> json) {
    return ChatDeletedHistory(
      messageId: json['messageId'],
      deletedBy: json['deletedBy'],
      deletedAt: DateTime.parse(json['deletedAt']),
    );
  }
}