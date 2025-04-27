import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ThemeController extends GetxController {
  // Reactive variable to store the current theme mode
  var themeMode = ThemeMode.system.obs;

  // Set the theme mode
  void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
    Get.changeThemeMode(mode);
  }

  // Get the current theme icon based on the theme mode
  IconData getThemeIcon() {
    switch (themeMode.value) {
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.light:
        return Icons.light_mode;
      default:
        return Icons.brightness_auto;
    }
  }
}