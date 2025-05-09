// lib/services/settings_service.dart
import 'package:chewata/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:chewata/services/auth_service.dart';

class SettingsService extends GetxService {
  static SettingsService get instance => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService.instance;

  // Update online status visibility
  Future<bool> updateOnlineStatusVisibility(bool showStatus) async {
    try {
      final userId = _authService.firebaseUser.value?.uid;
      if (userId == null) return false;

      await _firestore.collection('users').doc(userId).update({
        'showOnlineStatus': showStatus,
      });

      // Update the userModel in AuthService
      if (_authService.userModel.value != null) {
        final updatedUser = _authService.userModel.value!;
        _authService.userModel.value = UserModel(
          id: updatedUser.id,
          fullName: updatedUser.fullName,
          email: updatedUser.email,
          birthDate: updatedUser.birthDate,
          profilePicUrl: updatedUser.profilePicUrl,
          createdAt: updatedUser.createdAt,
          isOnline: updatedUser.isOnline,
          lastSeen: updatedUser.lastSeen,
          showOnlineStatus: showStatus,
          enableNotifications: updatedUser.enableNotifications,
        );
      }

      return true;
    } catch (e) {
      print('Error updating online status visibility: $e');
      return false;
    }
  }

  // Update notification preferences
  Future<bool> updateNotificationPreference(bool enableNotifications) async {
    try {
      final userId = _authService.firebaseUser.value?.uid;
      if (userId == null) return false;

      await _firestore.collection('users').doc(userId).update({
        'enableNotifications': enableNotifications,
      });

      // Update the userModel in AuthService
      if (_authService.userModel.value != null) {
        final updatedUser = _authService.userModel.value!;
        _authService.userModel.value = UserModel(
          id: updatedUser.id,
          fullName: updatedUser.fullName,
          email: updatedUser.email,
          birthDate: updatedUser.birthDate,
          profilePicUrl: updatedUser.profilePicUrl,
          createdAt: updatedUser.createdAt,
          isOnline: updatedUser.isOnline,
          lastSeen: updatedUser.lastSeen,
          showOnlineStatus: updatedUser.showOnlineStatus,
          enableNotifications: enableNotifications,
        );
      }

      return true;
    } catch (e) {
      print('Error updating notification preference: $e');
      return false;
    }
  }
}
