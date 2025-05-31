import 'dart:convert';
import 'package:http/http.dart' as http;
import 'chat_history.dart';
import 'chat_deleted_history.dart';
import 'chat_controller.dart';

class ChatSync {
  final String _baseUrl = "https://api.chatapp.com";
  final ChatController _controller = ChatController();
  bool _isOnline = true;

  // Sync chat history with server
  Future<void> syncChatHistory() async {
    try {
      if (!_isOnline) {
        print("Offline: Storing data locally");
        return;
      }
      final response = await http.post(
        Uri.parse("$_baseUrl/sync/history"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(_controller.getChatHistory("user1")
            .map((chat) => chat.toJson())
            .toList()),
      );
      if (response.statusCode == 200) {
        print("Chat history synced successfully");
      } else {
        print("Failed to sync chat history");
      }
    } catch (e) {
      print("Error syncing chat history: $e");
      _isOnline = false;
    }
  }

  // Sync deleted messages with server
  Future<void> syncDeletedHistory() async {
    try {
      if (!_isOnline) {
        print("Offline: Storing deleted data locally");
        return;
      }
      final response = await http.post(
        Uri.parse("$_baseUrl/sync/deleted"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(_controller.getDeletedHistory("user1")
            .map((record) => record.toJson())
            .toList()),
      );
      if (response.statusCode == 200) {
        print("Deleted history synced successfully");
      } else {
        print("Failed to sync deleted history");
      }
    } catch (e) {
      print("Error syncing deleted history: $e");
      _isOnline = false;
    }
  }

  // Fetch updated chat data from server
  Future<List<ChatHistory>> fetchUpdatedChatHistory() async {
    try {
      if (!_isOnline) return [];
      final response = await http.get(Uri.parse("$_baseUrl/history/user1"));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ChatHistory.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching chat history: $e");
      _isOnline = false;
      return [];
    }
  }

  // Update network status
  void setNetworkStatus(bool status) {
    _isOnline = status;
    if (_isOnline) {
      syncChatHistory();
      syncDeletedHistory();
    }
  }

  // Load dummy data for testing
  void loadDummyData() {
    _controller.loadDummyData();
    // Simulate initial sync
    syncChatHistory();
    syncDeletedHistory();
  }
  @override
  Future<void> syncChatData() async {
    try {
      await _sync.syncChatHistory();
      await _sync.syncDeletedHistory();
      print("Chat data synced successfully");
    } catch (e) {
      print("Error syncing chat data: $e");
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
  Future<void> updateUserStatus(String userId, bool isOnline) => throw UnimplementedError();
}