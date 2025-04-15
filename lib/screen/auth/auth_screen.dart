import 'package:flutter/material.dart';
import 'dart:ui';
import 'login_form.dart';
import 'signup_form.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Calculate dynamic height for the box
    double boxHeight;
    if (size.width < 600) {
      // Mobile view
      boxHeight = _currentPage == 0 ? size.height * 0.5 : size.height * 0.7;
    } else {
      // Desktop view
      boxHeight = _currentPage == 0 ? size.height * 0.6 : size.height * 0.8;
    }

    return Scaffold(
      body: Stack(
        children: [
          // Static background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/auth_images/login_background.jpg"),
                fit: BoxFit.cover, // Ensure the image covers the full screen
              ),
            ),
          ),
          // Content box with PageView
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: size.width > 600 ? 500 : size.width * 0.9,
              height: boxHeight, // Dynamic height
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(), // Disable swipe
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      children: [
                        // Login Form
                        Center(
                          child: LoginForm(onSwitchToSignUp: () {
                            _pageController.animateToPage(
                              1,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          }),
                        ),
                        // Sign Up Form
                        Center(
                          child: SignupForm(onSwitchToLogin: () {
                            _pageController.animateToPage(
                              0,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}