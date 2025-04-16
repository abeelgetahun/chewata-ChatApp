import 'package:flutter/material.dart';
import 'package:chewata/utils/constants/image_strings.dart';

class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key});

  @override
  Widget build(BuildContext context) {
    // Determine the current theme mode (light or dark)
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Select the appropriate background image based on the theme
    final backgroundImage = isDarkMode
        ? TImages.login_background_dark
        : TImages.login_background;

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(backgroundImage),
          fit: BoxFit.cover, // Ensure the image covers the full screen
        ),
      ),
    );
  }
}