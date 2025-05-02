import 'package:chewata/screen/chat/chat_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chewata/controller/auth_controller.dart';
import 'package:chewata/controller/navigation_controller.dart';
import 'package:chewata/controller/theme_controller.dart';
import 'package:chewata/controller/chat_controller.dart';
import 'package:chewata/services/auth_service.dart';
import 'package:chewata/screen/connect_screen.dart';
import 'package:chewata/screen/fun_screen.dart';
import 'package:chewata/screen/account_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the current theme mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Initialize controllers
    final AuthController authController = Get.find<AuthController>();
    final AuthService authService = Get.find<AuthService>();
    final ThemeController themeController = Get.find<ThemeController>();

    // Initialize navigation controller if not already done
    if (!Get.isRegistered<NavigationController>()) {
      Get.put(NavigationController());
    }
    final NavigationController navigationController = Get.find<NavigationController>();

    // Initialize chat controller if not already done
    if (!Get.isRegistered<ChatController>()) {
      Get.put(ChatController());
    }

    // Define the screens for each tab
    final List<Widget> screens = [
      _buildHomeContent(authService), // Chewata tab content
      const ConnectScreen(),
      const FunScreen(),
      const AccountScreen(),
    ];

    // PageController for PageView
    final PageController pageController = PageController();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [Colors.black, Colors.grey[900]!]
              : [Colors.white, Colors.grey[200]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // Transparent to show the gradient
        appBar: AppBar(
          backgroundColor: Colors.transparent, // Transparent app bar
          elevation: 0, // Remove shadow
          title: const Text(
            'Chewata',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              onPressed: () {
                // Show theme selection dialog
                _showThemeSelectionDialog(context, themeController);
              },
              icon: _buildAppBarIcon('assets/icons/dark_mode.svg', isDarkMode),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () {
                // Navigate to Search screen or show search bar
              },
              icon: _buildAppBarIcon('assets/icons/search.svg', isDarkMode),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () {
                // Your logout logic here
                AuthService.instance.logout();
              },
              icon: _buildAppBarIcon('assets/icons/logout.svg', isDarkMode),
            ),
          ],
        ),
        body: PageView(
          controller: pageController,
          onPageChanged: (index) {
            // Update the selected index in the NavigationController
            navigationController.changeIndex(index);
          },
          children: screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.black : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Obx(() => GNav(
                selectedIndex: navigationController.selectedIndex.value,
                onTabChange: (index) {
                  // Navigate to the selected page in the PageView
                  pageController.jumpToPage(index);
                },
                rippleColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                hoverColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
                gap: 8,
                activeColor: isDarkMode ? Colors.white : Colors.black,
                iconSize: 24,
                tabActiveBorder: isDarkMode ? Border.all(color: Colors.white, width: 1) : Border.all(color: Colors.black, width: 1),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                duration: const Duration(milliseconds: 400),
                tabBackgroundColor: Colors.transparent,
                color: isDarkMode ? Colors.black : Colors.white,
                tabs: [
                  _buildNavItem('chewata', 'assets/icons/home_chewata_nav.svg', isDarkMode),
                  _buildNavItem('connect', 'assets/icons/home_connect_nav.svg', isDarkMode),
                  _buildNavItem('fun', 'assets/icons/home_fun_nav.svg', isDarkMode),
                  _buildNavItem('account', 'assets/icons/home_account_nav.svg', isDarkMode),
                ],
              )),
            ),
          ),
        ),
      ),
    );
  }

  void _showThemeSelectionDialog(BuildContext context, ThemeController themeController) {
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
      trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).primaryColor) : null,
      onTap: () {
        onTap();
        Navigator.of(context).pop();
      },
    );
  }

  GButton _buildNavItem(String text, String iconPath, bool isDarkMode) {
    return GButton(
      icon: Icons.home, // Replace with an appropriate icon
      leading: CustomIcon( // Use leading for custom SVG icon
        iconPath: iconPath,
        isActive: true,
        isDarkMode: isDarkMode,
      ),
      text: text,
    );
  }

  Widget _buildAppBarIcon(String assetPath, bool isDarkMode) {
    // Adaptive color based on theme
    final iconColor = isDarkMode ? Colors.white : Colors.black;

    return SvgPicture.asset(
      assetPath,
      height: 24,
      width: 24,
      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      placeholderBuilder: (BuildContext context) => Icon(
        // Fallback icons based on which SVG failed to load
        assetPath.contains('search')
            ? Icons.search
            : assetPath.contains('dark_mode')
                ? Icons.dark_mode
                : assetPath.contains('logout')
                    ? Icons.logout
                    : Icons.error,
        color: iconColor,
        size: 24,
      ),
    );
  }

  // Update the _buildHomeContent method in home_screen.dart
Widget _buildHomeContent(AuthService authService) {
  return const ChatListScreen();
}
}

// Custom icon widget that handles SVG icons and adapts to theme
class CustomIcon extends StatelessWidget {
  final String iconPath;
  final bool isActive;
  final bool isDarkMode;

  const CustomIcon({
    Key? key,
    required this.iconPath,
    required this.isActive,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate the color based on active state and theme
    Color color;
    if (isActive) {
      color = isDarkMode ? Colors.white : Colors.black;
    } else {
      color = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    }

    return SvgPicture.asset(
      iconPath,
      height: 24,
      width: 24,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn), // Apply color filter
      placeholderBuilder: (BuildContext context) => Icon(
        Icons.error, // Fallback icon if SVG fails to load
        color: color,
        size: 24,
      ),
    );
  }
}