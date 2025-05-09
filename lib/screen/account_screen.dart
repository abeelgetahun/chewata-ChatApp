// lib/screen/account_screen.dart
import 'package:chewata/controller/privacy_setting_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chewata/controller/account_controller.dart';
import 'package:chewata/controller/theme_controller.dart';
import 'package:chewata/services/auth_service.dart';
import 'package:chewata/screen/account/personal_info_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final ThemeController themeController = Get.find<ThemeController>();

    // Initialize account controller if not already registered
    if (!Get.isRegistered<AccountController>()) {
      Get.put(AccountController());
    }
    final AccountController accountController = Get.find<AccountController>();

    return FutureBuilder(
      future: accountController.refreshUserData(),
      builder: (context, snapshot) {
        // Show loading indicator only if this is the first load
        if (snapshot.connectionState == ConnectionState.waiting &&
            accountController.user.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              // User profile section
              _buildProfileSection(context, accountController, isDarkMode),

              const SizedBox(height: 24),

              // Account control options
              _buildAccountOptions(context, isDarkMode),

              const SizedBox(height: 24),

              // App settings
              _buildAppSettings(context, isDarkMode, themeController),

              const SizedBox(height: 24),

              // Support and about
              _buildSupportAndAbout(context, isDarkMode),

              const SizedBox(height: 32),

              // Logout button
              _buildLogoutButton(context, isDarkMode),

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileSection(
    BuildContext context,
    AccountController controller,
    bool isDarkMode,
  ) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          height: 250,
          child: const Center(child: CircularProgressIndicator()),
        );
      }

      final user = controller.user.value;

      return Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Profile image
            CircleAvatar(
              radius: 50,
              backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
              backgroundImage:
                  user?.profilePicUrl != null && user!.profilePicUrl.isNotEmpty
                      ? NetworkImage(user.profilePicUrl)
                      : null,
              child:
                  user?.profilePicUrl == null || user!.profilePicUrl.isEmpty
                      ? Icon(
                        Icons.person,
                        size: 50,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      )
                      : null,
            ),

            const SizedBox(height: 16),

            // User name
            Text(
              user?.fullName ?? 'Guest User',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),

            const SizedBox(height: 8),

            // User email
            Text(
              user?.email ?? 'No email available',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAccountOptions(BuildContext context, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Account',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildOptionItem(
          context,
          'Personal Information',
          Icons.person_outline,
          () {
            Get.to(
              () => const PersonalInfoScreen(),
              transition: Transition.rightToLeft,
            );
          },
          isDarkMode,
        ),
      ],
    );
  }

  Widget _buildAppSettings(
    BuildContext context,
    bool isDarkMode,
    ThemeController themeController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'App Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildOptionItem(context, 'Appearance', Icons.color_lens_outlined, () {
          _showThemeSelectionDialog(context, themeController);
        }, isDarkMode),
        _buildOptionItem(context, 'Language', Icons.language, () {
          Get.snackbar(
            'Coming Soon',
            'This feature is under development',
            snackPosition: SnackPosition.BOTTOM,
          );
        }, isDarkMode),
        _buildOptionItem(
          context,
          'Privacy & Notifications',
          Icons.security,
          () {
            _showPrivacyAndNotificationsDialog(context, isDarkMode);
          },
          isDarkMode,
        ),
        _buildOptionItem(context, 'Data Usage', Icons.data_usage, () {
          Get.snackbar(
            'Coming Soon',
            'This feature is under development',
            snackPosition: SnackPosition.BOTTOM,
          );
        }, isDarkMode),
      ],
    );
  }

  Widget _buildSupportAndAbout(BuildContext context, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Support & About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildOptionItem(context, 'Help Center', Icons.help_outline, () {
          Get.snackbar(
            'Coming Soon',
            'This feature is under development',
            snackPosition: SnackPosition.BOTTOM,
          );
        }, isDarkMode),
        _buildOptionItem(context, 'About Chewata', Icons.info_outline, () {
          Get.snackbar(
            'Coming Soon',
            'This feature is under development',
            snackPosition: SnackPosition.BOTTOM,
          );
        }, isDarkMode),
        _buildOptionItem(
          context,
          'Terms & Privacy Policy',
          Icons.description_outlined,
          () {
            Get.snackbar(
              'Coming Soon',
              'This feature is under development',
              snackPosition: SnackPosition.BOTTOM,
            );
          },
          isDarkMode,
        ),
      ],
    );
  }

  Widget _buildOptionItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
    bool isDarkMode,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          _showLogoutConfirmationDialog(context);
        },
        icon: Icon(
          Icons.logout,
          color: isDarkMode ? Colors.black : Colors.white,
        ),
        label: Text(
          'Log Out',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.black : Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDarkMode ? Colors.white : Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Logout logic
                AuthService.instance.logout();
              },
              child: const Text('Log Out'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        );
      },
    );
  }

  void _showThemeSelectionDialog(
    BuildContext context,
    ThemeController themeController,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Theme'),
          content: SizedBox(
            width: double.minPositive,
            child: GetBuilder<ThemeController>(
              builder: (controller) {
                final currentThemeMode = controller.getThemeMode();
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildThemeOption(
                      context,
                      'Light',
                      Icons.light_mode,
                      currentThemeMode == ThemeMode.light,
                      () => controller.setThemeMode(ThemeMode.light),
                    ),
                    const Divider(),
                    _buildThemeOption(
                      context,
                      'Dark',
                      Icons.dark_mode,
                      currentThemeMode == ThemeMode.dark,
                      () => controller.setThemeMode(ThemeMode.dark),
                    ),
                    const Divider(),
                    _buildThemeOption(
                      context,
                      'System',
                      Icons.settings_suggest,
                      currentThemeMode == ThemeMode.system,
                      () => controller.setThemeMode(ThemeMode.system),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String title,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return ListTile(
      title: Text(title),
      leading: Icon(icon),
      trailing:
          isSelected
              ? Icon(Icons.check, color: Theme.of(context).primaryColor)
              : null,
      onTap: () {
        onTap();
        Navigator.of(context).pop();
      },
    );
  }
}

void _showPrivacyAndNotificationsDialog(BuildContext context, bool isDarkMode) {
  // Ensure the controller is registered
  if (!Get.isRegistered<PrivacySettingsController>()) {
    Get.put(PrivacySettingsController());
  }

  final PrivacySettingsController controller =
      Get.find<PrivacySettingsController>();

  // Make sure we have the latest settings
  controller.loadCurrentSettings();

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withOpacity(0.5),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation1, animation2) => Container(), // Not used
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
      );

      return ScaleTransition(
        scale: curvedAnimation,
        child: FadeTransition(
          opacity: animation,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
            title: Text(
              'Privacy & Notifications',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Obx(() {
              return SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Online Status
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Online Status',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Show others when you are online',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Show Online Status',
                                style: TextStyle(
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              Switch(
                                value: controller.showOnlineStatus.value,
                                onChanged:
                                    controller.isLoading.value
                                        ? null
                                        : (value) async {
                                          final success = await controller
                                              .updateOnlineStatusVisibility(
                                                value,
                                              );
                                          if (!success) {
                                            Get.snackbar(
                                              'Error',
                                              'Failed to update online status preference',
                                              snackPosition:
                                                  SnackPosition.BOTTOM,
                                            );
                                          }
                                        },
                                activeColor: Theme.of(context).primaryColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Notifications
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifications',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Manage notification preferences',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Enable Message Notifications',
                                style: TextStyle(
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              Switch(
                                value: controller.enableNotifications.value,
                                onChanged:
                                    controller.isLoading.value
                                        ? null
                                        : (value) async {
                                          final success = await controller
                                              .updateNotificationPreference(
                                                value,
                                              );
                                          if (!success) {
                                            Get.snackbar(
                                              'Error',
                                              'Failed to update notification preference',
                                              snackPosition:
                                                  SnackPosition.BOTTOM,
                                            );
                                          }
                                        },
                                activeColor: Theme.of(context).primaryColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    if (controller.isLoading.value)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Center(
                          child: SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Close',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
