import 'package:flutter/material.dart';
import 'package:chewata/screen/auth/login_form.dart';
import 'package:chewata/screen/auth/signup_form.dart';
import 'package:chewata/screen/auth/widgets/auth_background.dart';
import 'package:chewata/screen/auth/widgets/auth_box.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _showLogin = true;

  void _toggleView() {
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
            child: Center(
              child: AuthBox(
                width: formWidth,
                child: _showLogin
                    ? LoginForm(onSwitchToSignUp: _toggleView)
                    : SignupForm(onSwitchToLogin: _toggleView),
              ),
            ),
          ),
        ],
      ),
    );
  }
}