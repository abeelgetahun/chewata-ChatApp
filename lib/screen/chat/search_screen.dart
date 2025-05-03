// lib/screen/search_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chewata/controller/chat_controller.dart';

class SearchScreen extends StatelessWidget {
  SearchScreen({Key? key}) : super(key: key);

  final ChatController _chatController = Get.find<ChatController>();
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search for users by email',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onSubmitted: (value) {
            _chatController.searchUserByEmail(value);
          },
        ),
      ),
      body: Obx(() {
        if (_chatController.isSearching.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_chatController.searchedUser.value != null) {
          final user = _chatController.searchedUser.value!;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(user.fullName),
            subtitle: Text(user.email),
            trailing: ElevatedButton(
              onPressed: () async {
                try {
                  await _chatController.createOrGetChatWithUser(user.id);
                  
                  // Wait for the chat to be created and get its ID
                  final chatId = _chatController.selectedChatId.value;
                  if (chatId.isNotEmpty) {
                    // Navigate directly to the chat screen without clearing the entire stack
                    Get.toNamed('/chat/$chatId');
                  }
                } catch (e) {
                  Get.snackbar('Error', 'Failed to start chat');
                  print('Navigation error: $e');
                }
              },
              child: Obx(() => _chatController.isLoading.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Chat')),
            ),
          );
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search,
                size: 64,
                color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Search for users by email',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}