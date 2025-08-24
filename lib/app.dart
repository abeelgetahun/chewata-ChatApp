import 'package:chewata/controller/account_controller.dart';
import 'package:chewata/controller/auth_controller.dart';
import 'package:chewata/controller/chat_controller.dart';
import 'package:chewata/controller/theme_controller.dart';
import 'package:chewata/screen/auth/auth_screen.dart';
import 'package:chewata/screen/chat/app_life_cycle_service.dart';
import 'package:chewata/screen/chat/chat_screen.dart';
import 'package:chewata/screen/chat/search_screen.dart';
import 'package:chewata/screen/home_screen.dart';
import 'package:chewata/screen/GroupChatScreen.dart';
import 'package:chewata/screen/onboarding/onboarding.dart';
import 'package:chewata/services/auth_service.dart';
import 'package:chewata/services/chat_service.dart';
import 'package:chewata/services/setting_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  // A navigator observer to catch route changes as activity signals
  final _routeObserver = RouteObserver<PageRoute<dynamic>>();

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    // Initialize Firebase and other services here if needed
  }

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

        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          // For legacy code that reads Theme.of(context).primaryColor:
          primaryColor: const Color.fromARGB(255, 23, 105, 172),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Color.fromARGB(255, 32, 122, 196),
            brightness: Brightness.dark,
          ),
          primaryColor: Color.fromARGB(255, 25, 108, 176),
        ),
        initialRoute: '/',
        // Any user gesture will reset the inactivity timer
        builder: (context, child) {
          return Listener(
            onPointerDown: (_) => AuthService.instance.resetSessionTimer(),
            child: Focus(
              autofocus: true,
              onKeyEvent: (_, __) {
                AuthService.instance.resetSessionTimer();
                return KeyEventResult.ignored;
              },
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
        // Add navigator observers to detect navigation (considered activity)
        navigatorObservers: [
          _routeObserver,
          _ActivityObserver(
            onActivity: () => AuthService.instance.resetSessionTimer(),
          ),
        ],
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
            name: '/group-chat/:chatId',
            page: () {
              final chatId = Get.parameters['chatId']!;
              return GroupChatScreen(chatId: chatId);
            },
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

// A simple NavigatorObserver to consider navigation as activity
class _ActivityObserver extends NavigatorObserver {
  final VoidCallback onActivity;
  _ActivityObserver({required this.onActivity});

  void _hit() {
    try {
      onActivity();
    } catch (_) {}
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    _hit();
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    _hit();
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    _hit();
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didStartUserGesture(Route route, Route? previousRoute) {
    _hit();
    super.didStartUserGesture(route, previousRoute);
  }

  @override
  void didStopUserGesture() {
    _hit();
    super.didStopUserGesture();
  }
}
