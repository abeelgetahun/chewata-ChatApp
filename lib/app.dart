import 'package:chewata/controller/account_controller.dart';
import 'package:chewata/controller/auth_controller.dart';
import 'package:chewata/controller/chat_controller.dart';
import 'package:chewata/controller/theme_controller.dart';
import 'package:chewata/screen/auth/auth_screen.dart';
import 'package:chewata/screen/chat/app_life_cycle_service.dart';
import 'package:chewata/screen/chat/chat_screen.dart';
import 'package:chewata/screen/chat/search_screen.dart';
import 'package:chewata/screen/home_screen.dart';
import 'package:chewata/screen/onboarding/onboarding.dart';
import 'package:chewata/services/auth_service.dart';
import 'package:chewata/services/chat_service.dart';
import 'package:chewata/services/setting_service.dart';
import 'package:chewata/utils/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize services with Get
    Get.put(AuthService(), permanent: true);
    Get.put(AuthController(), permanent: true);
    Get.put(ChatService(), permanent: true);
    Get.put(ChatController());
    Get.put(AppLifecycleService(), permanent: true);
    // Add this line in the App class's build method, after existing Get.put statements:
    Get.put(AccountController(), permanent: true);

    Get.put(SettingsService());
    // Get theme controller

    final ThemeController themeController = Get.find<ThemeController>();

    return Obx(
      () => GetMaterialApp(
        title: 'Chewata chat',
        themeMode: themeController.getThemeMode(),
        theme: TAppTheme.lightTheme,
        darkTheme: TAppTheme.darkTheme,
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => _determineInitialScreen()),
          GetPage(name: '/onboarding', page: () => const OnBoardingScreen()),
          GetPage(name: '/auth', page: () => const AuthScreen()),
          GetPage(name: '/home', page: () => const HomeScreen()),
          GetPage(
            name: '/chat/:chatId',
            page: () {
              final chatId = Get.parameters['chatId']!;
              return ChatScreen(chatId: chatId);
            },
            binding: BindingsBuilder(() {
              if (!Get.isRegistered<ChatController>()) {
                Get.put(ChatController());
              }
            }),
          ),
          GetPage(
            name: '/search',
            page: () => SearchScreen(),
          ), // Add search route
        ],
      ),
    );
  }

  Widget _determineInitialScreen() {
    return Obx(() {
      try {
        final firebaseUser = AuthService.instance.firebaseUser.value;

        // If the user is logged in, show home screen
        if (firebaseUser != null) {
          return const HomeScreen();
        }

        // Otherwise show onboarding
        return const OnBoardingScreen();
      } catch (e) {
        // If there's an error, default to the onboarding screen
        return const OnBoardingScreen();
      }
    });
  }
}
