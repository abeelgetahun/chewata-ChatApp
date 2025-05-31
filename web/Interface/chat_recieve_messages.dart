import 'chat_history.dart';
import 'chat_controller.dart';

class ChatReceiveMessages implements ChatInterface {
  final ChatController _controller = ChatController();

  @override
  Future<List<ChatHistory>> receiveMessages(String userId) async {
    try {
      if (userId.isEmpty) throw Exception("User ID cannot be empty");
      final messages = _controller.getChatHistory(userId);
      print("Messages retrieved for user $userId: ${messages.length} messages");
      return messages;
    } catch (e) {
      print("Error receiving messages: $e");
      rethrow;
    }
  }

  // Unimplemented methods
  @override
  Future<void> sendMessage(String id, String message, String sender, String receiver) => throw UnimplementedError();
  @override
  Future<void> deleteMessage(String messageId, String deletedBy) => throw UnimplementedError();
  @override
  Future<void> syncChatData() => throw UnimplementedError();
  @override
  Future<void> updateUserStatus(String userId, bool isOnline) => throw UnimplementedError();
}