import 'chat_controller.dart';

class ChatDeleteMessage implements ChatInterface {
  final ChatController _controller = ChatController();

  @override
  Future<void> deleteMessage(String messageId, String deletedBy) async {
    try {
      if (messageId.isEmpty || deletedBy.isEmpty) {
        throw Exception("Message ID and deletedBy must not be empty");
      }
      _controller.deleteMessage(messageId, deletedBy);
      print("Message $messageId deleted by $deletedBy");
    } catch (e) {
      print("Error deleting message: $e");
      rethrow;
    }
  }

  // Unimplemented methods
  @override
  Future<void> sendMessage(String id, String message, String sender, String receiver) => throw UnimplementedError();
  @override
  Future<List<ChatHistory>> receiveMessages(String userId) => throw UnimplementedError();
  @override
  Future<void> syncChatData() => throw UnimplementedError();
  @override
  Future<void> updateUserStatus(String userId, bool isOnline) => throw UnimplementedError();
}