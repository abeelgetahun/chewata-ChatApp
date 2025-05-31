import 'chat_history.dart';
import 'chat_controller.dart';

class ChatSendMessage implements ChatInterface {
  final ChatController _controller = ChatController();

  @override
  Future<void> sendMessage(String id, String message, String sender, String receiver) async {
    try {
      if (message.isEmpty) throw Exception("Message cannot be empty");
      if (id.isEmpty || sender.isEmpty || receiver.isEmpty) {
        throw Exception("ID, sender, and receiver must not be empty");
      }
      _controller.sendMessage(id, message, sender, receiver);
      print("Message sent successfully: $message");
    } catch (e) {
      print("Error sending message: $e");
      rethrow;
    }
  }

  // Unimplemented methods
  @override
  Future<List<ChatHistory>> receiveMessages(String userId) => throw UnimplementedError();
  @override
  Future<void> deleteMessage(String messageId, String deletedBy) => throw UnimplementedError();
  @override
  Future<void> syncChatData() => throw UnimplementedError();
  @override
  Future<void> updateUserStatus(String userId, bool isOnline) => throw UnimplementedError();
}