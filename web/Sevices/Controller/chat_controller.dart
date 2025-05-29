import 'chat_history.dart';
import 'chat_deleted_history.dart';

class ChatController {
  List<ChatHistory> _chatHistory = [];
  List<ChatDeletedHistory> _deletedHistory = [];

  // Add a new message to chat history
  void sendMessage(String id, String message, String sender, String receiver) {
    final newMessage = ChatHistory(
      id: id,
      message: message,
      sender: sender,
      receiver: receiver,
      timestamp: DateTime.now(),
    );
    _chatHistory.add(newMessage);
  }

  // Delete a message and log it in deleted history
  void deleteMessage(String messageId, String deletedBy) {
    _chatHistory.removeWhere((chat) => chat.id == messageId);
    final deletedRecord = ChatDeletedHistory(
      messageId: messageId,
      deletedBy: deletedBy,
      deletedAt: DateTime.now(),
    );
    _deletedHistory.add(deletedRecord);
  }

  // Get all chat messages for a specific user
  List<ChatHistory> getChatHistory(String userId) {
    return _chatHistory
        .where((chat) => chat.sender == userId || chat.receiver == userId)
        .toList();
  } 

  // Get all deleted messages for a specific user
  List<ChatDeletedHistory> getDeletedHistory(String userId) {
    return _deletedHistory.where((record) => record.deletedBy == userId).toList();
  }

  // Initialize with dummy data for testing
  void loadDummyData() {
    _chatHistory = [
      ChatHistory(
        id: "msg1",
        message: "Hello, how are you?",
        sender: "user1",
        receiver: "user2",
        timestamp: DateTime(2025, 5, 29, 21, 0), // 9:00 PM EAT
        isRead: true,
      ),
      ChatHistory(
        id: "msg2",
        message: "I'm good, thanks!",
        sender: "user2",
        receiver: "user1",
        timestamp: DateTime(2025, 5, 29, 21, 5), // 9:05 PM EAT
        isRead: false,
      ),
    ];

    _deletedHistory = [
      ChatDeletedHistory(
        messageId: "msg3",
        deletedBy: "user1",
        deletedAt: DateTime(2025, 5, 29, 21, 8), // 9:08 PM EAT
      ),
    ];
  }
}