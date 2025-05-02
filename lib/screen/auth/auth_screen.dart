// This is imported file
import 'package:flutter/material.dart';
import 'package:chewata/screen/auth/login_form.dart';
import 'package:chewata/screen/auth/signup_form.dart';
import 'package:chewata/screen/auth/widgets/auth_background.dart';
import 'package:chewata/screen/auth/widgets/auth_box.dart';
import 'package:chewata/controller/auth_controller.dart';
import 'package:get/get.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _showLogin = true;
  final AuthController _authController = Get.find<AuthController>();

  void _toggleView() {
    // Clear form data when switching between login and signup
    if (_showLogin) {
      _authController.clearSignupForm();
    } else {
      _authController.clearLoginForm();
    }

    setState(() {
      _showLogin = !_showLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final formWidth = screenWidth > 600 ? 500.0 : screenWidth * 0.9;

    return Scaffold(
      body: Stack(
        children: [
          // Background that changes based on theme
          const AuthBackground(),

          // Main content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate the maximum height available for the blurred box
                final maxHeight =
                    constraints.maxHeight -
                    60; // 30 padding from top and bottom
                final boxHeight = _showLogin ? 400.0 : 500.0;

                // Ensure the box height does not exceed the available height
                final adjustedHeight =
                    boxHeight > maxHeight ? maxHeight : boxHeight;

                return Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    width: formWidth,
                    height: adjustedHeight,
                    child: AuthBox(
                      width: formWidth,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.0, 0.1),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child:
                            _showLogin
                                ? LoginForm(
                                  key: const ValueKey('LoginForm'),
                                  onSwitchToSignUp: _toggleView,
                                )
                                : SignupForm(
                                  key: const ValueKey('SignupForm'),
                                  onSwitchToLogin: _toggleView,
                                ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Guest login button
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  _authController.continueAsGuest();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Continue as Guest',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Ensure we clear all sensitive data when this screen is disposed
    _authController.clearAllForms();
    super.dispose();
  }
}
