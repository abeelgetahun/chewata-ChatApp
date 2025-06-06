import 'package:chewata/screen/randomChat_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chewata/controller/auth_controller.dart';
import 'package:chewata/services/auth_service.dart';
import 'package:chewata/models/user_model.dart';
import 'package:chewata/models/chat_model.dart';
import 'package:chewata/models/message_model.dart';
import 'dart:math';
 
class ConnectController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = Get.find<AuthService>();
  
  Rx<bool> isSearching = false.obs;
  Rx<String?> currentRandomChatId = Rx<String?>(null);
  Rx<UserModel?> randomChatPartner = Rx<UserModel?>(null);
  Rx<int> searchDuration = 0.obs; // 0 = 1 min, 1 = 3 min, 2 = 5 min
  
  // For UI feedback
  Rx<String> statusMessage = "Ready to connect".obs;
  Rx<bool> isLoading = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    // Check if user is already in a random chat
    checkExistingRandomChat();
  }
  
  // Function to check if user is already in a random chat
  Future<void> checkExistingRandomChat() async {
    try {
      isLoading.value = true;
      
      // ...existing code...
final currentUserId = _authService.firebaseUser.value?.uid;
// ...existing code...
      if (currentUserId == null) return;
      
      // Query chats where user is a participant and has metadata.isRandomChat = true
      final chatSnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .get();
      
      for (var doc in chatSnapshot.docs) {
        Map<String, dynamic> data = doc.data();
        // Check if this is a random chat
        if (data['metadata'] != null && 
            data['metadata']['isRandomChat'] == true && 
            data['metadata']['isActive'] == true) {
          // Found an active random chat
          currentRandomChatId.value = doc.id;
          
          // Get the other participant
          List<String> participants = List<String>.from(data['participants']);
          String partnerId = participants.firstWhere((id) => id != currentUserId);
          
          // Fetch partner details
          final partnerSnapshot = await _firestore.collection('users').doc(partnerId).get();
          if (partnerSnapshot.exists) {
            randomChatPartner.value = UserModel.fromMap(partnerSnapshot.data()!);
          }
          
          statusMessage.value = "You're in an active random chat";
          break;
        }
      }
      
    } catch (e) {
      print('Error checking existing random chat: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  // Find a random user to chat with
  Future<void> startRandomChat() async {
    if (isSearching.value) return;
    
    try {
      isSearching.value = true;
      isLoading.value = true;
      statusMessage.value = "Looking for someone to chat with...";
      
     
    final currentUserId = _authService.firebaseUser.value?.uid;
      // ...existing code...
      if (currentUserId == null) {
        statusMessage.value = "You need to be logged in";
        return;
      }
      
      // Get current user details for birthdate comparison
      final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (!currentUserDoc.exists) {
        statusMessage.value = "User profile not found";
        return;
      }
      
      final currentUser = UserModel.fromMap(currentUserDoc.data()!);
      
      // Define time threshold based on selected duration
      final now = DateTime.now();
      Duration timeThreshold;
      
      switch (searchDuration.value) {
        case 0:
          timeThreshold = const Duration(minutes: 1);
          break;
        case 1:
          timeThreshold = const Duration(minutes: 3);
          break;
        case 2:
          timeThreshold = const Duration(minutes: 5);
          break;
        default:
          timeThreshold = const Duration(minutes: 1);
      }
      
      DateTime thresholdTime = now.subtract(timeThreshold);
      
      // First try to find online users
      var query = _firestore.collection('users')
          .where('id', isNotEqualTo: currentUserId)
          .where('isOnline', isEqualTo: true)
          .limit(20);
      
      var querySnapshot = await query.get();
      List<UserModel> potentialMatches = [];
      
      // If no online users, try users who were active within the threshold
      if (querySnapshot.docs.isEmpty) {
        statusMessage.value = "Looking for recently active users...";
        query = _firestore.collection('users')
            .where('id', isNotEqualTo: currentUserId)
            .where('lastSeen', isGreaterThan: Timestamp.fromDate(thresholdTime))
            .limit(20);
        
        querySnapshot = await query.get();
      }
      
      // Process the results
      for (var doc in querySnapshot.docs) {
        UserModel user = UserModel.fromMap(doc.data());
        potentialMatches.add(user);
      }
      
      if (potentialMatches.isEmpty) {
        statusMessage.value = "No users available right now. Try again later.";
        return;
      }
      
      // Sort by birthdate closeness (age similarity)
      potentialMatches.sort((a, b) {
        int daysDiffA = (a.birthDate.difference(currentUser.birthDate).inDays).abs();
        int daysDiffB = (b.birthDate.difference(currentUser.birthDate).inDays).abs();
        return daysDiffA.compareTo(daysDiffB);
      });
      
      // Select a random user from the top 5 closest matches (or fewer if less than 5 available)
      final random = Random();
      int selectIndex = random.nextInt(min(5, potentialMatches.length));
      UserModel selectedUser = potentialMatches[selectIndex];
      
      // Create a new chat
      final chatRef = _firestore.collection('chats').doc();
      
      final newChat = ChatModel(
        id: chatRef.id,
        participants: [currentUserId, selectedUser.id],
        createdAt: DateTime.now(),
        unreadCount: {
          currentUserId: 0,
          selectedUser.id: 0,
        },
      );
      
      // Add metadata for random chat
      Map<String, dynamic> chatData = newChat.toMap();
      chatData['metadata'] = {
        'isRandomChat': true,
        'isActive': true,
        'startedAt': FieldValue.serverTimestamp(),
      };
      
      await chatRef.set(chatData);
      
      // Save the chat details
      currentRandomChatId.value = chatRef.id;
      randomChatPartner.value = selectedUser;
      
      // Navigate to chat screen
      Get.to(() => RandomChatScreen(
        chatId: chatRef.id,
        partner: selectedUser,
      ));
      
      statusMessage.value = "Connected with ${selectedUser.fullName}";
      
    } catch (e) {
      print('Error starting random chat: $e');
      statusMessage.value = "Error connecting. Please try again.";
    } finally {
      isSearching.value = false;
      isLoading.value = false;
    }
  }
  
  // End the random chat
  Future<void> endRandomChat() async {
    if (currentRandomChatId.value == null) return;
    
    try {
      isLoading.value = true;
      statusMessage.value = "Ending chat...";
      
      // Update the chat metadata to mark it as inactive
      await _firestore.collection('chats').doc(currentRandomChatId.value).update({
        'metadata.isActive': false,
        'metadata.endedAt': FieldValue.serverTimestamp(),
      });
      
      // Send a system message indicating the chat has ended
      final messageRef = _firestore.collection('messages').doc();
      final systemMessage = MessageModel(
        id: messageRef.id,
        chatId: currentRandomChatId.value!,
        senderId: 'system',
        text: 'This chat has ended.',
        sentAt: DateTime.now(),
        isRead: false,
        isDelivered: true,
        metadata: {'isSystemMessage': true},
      );
      
      await messageRef.set(systemMessage.toMap());
      
      // Reset the controller state
      currentRandomChatId.value = null;
      randomChatPartner.value = null;
      statusMessage.value = "Chat ended. Start a new one when you're ready!";
      
    } catch (e) {
      print('Error ending random chat: $e');
      statusMessage.value = "Error ending chat. Please try again.";
    } finally {
      isLoading.value = false;
    }
  }
}

class ConnectScreen extends StatelessWidget {
  const ConnectScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the current theme mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Initialize the controller
    final ConnectController connectController = Get.put(ConnectController());
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Connect icon
              SvgPicture.asset(
                'assets/icons/connect_people.svg',
                height: 120,
                width: 120,
                colorFilter: ColorFilter.mode(
                  isDarkMode ? Colors.white : Colors.black,
                  BlendMode.srcIn,
                ),
                placeholderBuilder: (context) => Icon(
                  Icons.people,
                  size: 120,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 32),
              
              // Title
              Text(
                'Random Connections',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              
              // Description
              Text(
                'Connect with random users and chat anonymously. Meet new people and make new friends!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 32),
              
              // Status message
              Obx(() => Text(
                connectController.statusMessage.value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              )),
              const SizedBox(height: 16),
              
              // Active chat indicator or duration selection
              Obx(() {
                if (connectController.currentRandomChatId.value != null) {
                  // Show active chat indicator
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Active Random Chat',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (connectController.randomChatPartner.value != null) {
                            Get.to(() => RandomChatScreen(
                              chatId: connectController.currentRandomChatId.value!,
                              partner: connectController.randomChatPartner.value!,
                            ));
                          }
                        },
                        icon: const Icon(Icons.message),
                        label: const Text('Go to Chat'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  // Show search duration selection
                  return Column(
                    children: [
                      const Text(
                        'Search for users active within:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildDurationOption(connectController, 0, '1 min', context),
                          const SizedBox(width: 8),
                          _buildDurationOption(connectController, 1, '3 min', context),
                          const SizedBox(width: 8),
                          _buildDurationOption(connectController, 2, '5 min', context),
                        ],
                      ),
                    ],
                  );
                }
              }),
              const SizedBox(height: 32),
              
              // Action Button
              Obx(() {
                if (connectController.isLoading.value) {
                  return const CircularProgressIndicator();
                } else if (connectController.currentRandomChatId.value != null) {
                  return ElevatedButton.icon(
                    onPressed: () => connectController.endRandomChat(),
                    icon: const Icon(Icons.close),
                    label: const Text('End Random Chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                } else {
                  return ElevatedButton.icon(
                    onPressed: () => connectController.startRandomChat(),
                    icon: const Icon(Icons.shuffle),
                    label: const Text('Start Random Chat'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              }),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDurationOption(
    ConnectController controller, 
    int durationIndex, 
    String label,
    BuildContext context,
  ) {
    return Obx(() {
      final isSelected = controller.searchDuration.value == durationIndex;
      return InkWell(
        onTap: () => controller.searchDuration.value = durationIndex,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
            border: Border.all(
              color: isSelected 
                  ? Theme.of(context).primaryColor 
                  : Theme.of(context).dividerColor,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected 
                  ? Colors.white 
                  : Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );
    });
  }
}