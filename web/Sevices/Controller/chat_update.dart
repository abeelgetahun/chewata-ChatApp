import 'chat_user_profile.dart';

class ChatUpdateStatus implements ChatInterface {
  final List<UserProfile> _users = [];

  @override
  Future<void> updateUserStatus(String userId, bool isOnline) async {
    try {
      if (userId.isEmpty) throw Exception("User ID cannot be empty");
      final userIndex = _users.indexWhere((user) => user.id == userId);
      if (userIndex == -1) throw Exception("User not found");
      final updatedUser = UserProfile(
        id: _users[userIndex].id,
        name: _users[userIndex].name,
        avatarUrl: _users[userIndex].avatarUrl,
        isOnline: isOnline,
        lastSeen: isOnline ? DateTime.now() : _users[userIndex].lastSeen,
        email: _users[userIndex].email,
        phoneNumber: _users[userIndex].phoneNumber,
        bio: _users[userIndex].bio,
        friends: _users[userIndex].friends,
      );
      _users[userIndex] = updatedUser;
      print("User $userId status updated: Online = $isOnline");
    } catch (e) {
      print("Error updating user status: $e");
      rethrow;
    }
  }

  @override
  Future<void> sendMessage(String id, String message, String sender, String receiver) => throw UnimplementedError();
  @override
  Future<List<ChatHistory>> receiveMessages(String userId) => throw UnimplementedError();
  @override
  Future<void> deleteMessage(String messageId, String deletedBy) => throw UnimplementedError();
  @override
  Future<void> syncChatData() => throw UnimplementedError();
}