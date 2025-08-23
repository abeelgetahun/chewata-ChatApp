// lib/screen/account_screen.dart
import 'package:chewata/controller/privacy_setting_controller.dart';
import 'package:chewata/screen/account/about_app_screen.dart';
import 'package:chewata/screen/account/help_center_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:chewata/controller/account_controller.dart';
import 'package:chewata/controller/theme_controller.dart';
import 'package:chewata/services/auth_service.dart';
import 'package:chewata/screen/account/personal_info_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final ThemeController themeController;
  late final AccountController accountController;

  @override
  void initState() {
    super.initState();
    // Ensure controllers are available once
    if (!Get.isRegistered<AccountController>()) {
      Get.put(AccountController());
    }
    accountController = Get.find<AccountController>();
    themeController = Get.find<ThemeController>();

    // Defer data refresh to after first frame to avoid triggering Obx during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      accountController.refreshUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),

          // Profile section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Obx(() {
                final user = accountController.user.value;
                final loading = accountController.isLoading.value;
                if (loading) {
                  return Center(
                    child: SizedBox(
                      height: 28,
                      width: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  );
                }
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor:
                          isDarkMode ? Colors.grey[700] : Colors.grey[300],
                      backgroundImage:
                          (user?.profilePicUrl != null &&
                                  user!.profilePicUrl.isNotEmpty)
                              ? NetworkImage(user.profilePicUrl)
                              : null,
                      child:
                          (user?.profilePicUrl == null ||
                                  user!.profilePicUrl.isEmpty)
                              ? Icon(
                                Icons.person,
                                size: 36,
                                color:
                                    isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                              )
                              : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Guest User',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.ubuntu(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? 'No email available',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.ubuntu(
                              fontSize: 14,
                              color:
                                  isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        Get.to(
                          () => const PersonalInfoScreen(),
                          transition: Transition.rightToLeft,
                        );
                      },
                      child: Text(
                        'Edit',
                        style: GoogleFonts.ubuntu(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),

          const SizedBox(height: 24),
          _buildAccountOptions(context, isDarkMode),
          const SizedBox(height: 24),
          _buildAppSettings(context, isDarkMode, themeController),
          const SizedBox(height: 24),
          _buildSupportAndAbout(context, isDarkMode),
          const SizedBox(height: 32),
          _buildLogoutButton(context, isDarkMode),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAccountOptions(BuildContext context, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Account',
            style: GoogleFonts.ubuntu(
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
            style: GoogleFonts.ubuntu(
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
        // _buildOptionItem(context, 'Language', Icons.language, () {
        //   Get.snackbar(
        //     'Coming Soon',
        //     'This feature is under development',
        //     snackPosition: SnackPosition.BOTTOM,
        //   );
        // }, isDarkMode),
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
            style: GoogleFonts.ubuntu(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildOptionItem(context, 'Help Center', Icons.help_outline, () {
          _showHelpCenterScreen(context, isDarkMode);
        }, isDarkMode),
        _buildOptionItem(context, 'About Chewata', Icons.info_outline, () {
          _showAboutAppScreen(context, isDarkMode);
        }, isDarkMode),
        // _buildOptionItem(
        //   context,
        //   'Terms & Privacy Policy',
        //   Icons.description_outlined,
        //   () {
        //     _showTermsAndPrivacyScreen(context, isDarkMode);
        //   },
        //   isDarkMode,
        // ),
      ],
    );
  }

  // Help Center Screen
  void _showHelpCenterScreen(BuildContext context, bool isDarkMode) {
    Get.to(
      () => HelpCenterScreen(),
      transition: Transition.rightToLeftWithFade,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  // About App Screen
  void _showAboutAppScreen(BuildContext context, bool isDarkMode) {
    Get.to(
      () => AboutAppScreen(),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 300),
    );
  }

  // Terms & Privacy currently unused

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
                style: GoogleFonts.ubuntu(
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
          style: GoogleFonts.roboto(
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

  // Force refresh the settings from the user model
  controller.loadCurrentSettings();

  // Add debug logs to verify the values
  print('Current showOnlineStatus: ${controller.showOnlineStatus.value}');
  print('Current enableNotifications: ${controller.enableNotifications.value}');

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
            scrollable: true,
            backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
            title: Text(
              'Privacy & Notifications',
              style: GoogleFonts.ubuntu(
                color: isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Obx(() {
              final maxHeight = MediaQuery.of(context).size.height * 0.7;
              return ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Online Status
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              isDarkMode ? Colors.grey[800] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Online Status',
                              style: GoogleFonts.ubuntu(
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Show others when you are online (Note: hiding your status means you won\'t see others\' status either)',
                              style: GoogleFonts.ubuntu(
                                fontSize: 12,
                                color:
                                    isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Show Online Status',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.ubuntu(
                                      color:
                                          isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                    ),
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
                          color:
                              isDarkMode ? Colors.grey[800] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notifications',
                              style: GoogleFonts.ubuntu(
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Manage notification preferences',
                              style: GoogleFonts.ubuntu(
                                fontSize: 12,
                                color:
                                    isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Enable Message Notifications',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.ubuntu(
                                      color:
                                          isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                    ),
                                  ),
                                ),
                                // Notifications are locked to ON (sample feature)
                                AbsorbPointer(
                                  absorbing: true,
                                  child: Switch(
                                    value: true,
                                    onChanged: null, // disabled
                                    activeColor: Theme.of(context).primaryColor,
                                  ),
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
                  style: GoogleFonts.ubuntu(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
