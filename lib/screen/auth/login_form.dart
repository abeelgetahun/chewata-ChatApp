// lib/screen/auth/login_form.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chewata/controller/auth_controller.dart';
import 'package:chewata/services/auth_service.dart';

class LoginForm extends StatefulWidget {
  final VoidCallback onSwitchToSignUp;

  const LoginForm({super.key, required this.onSwitchToSignUp});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final AuthController _authController = Get.put(AuthController());
  final AuthService _authService = Get.find<AuthService>();
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _authController.loginFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Welcome to Chewata",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: "Poppins",
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Email input field
            _buildInputField(
              controller: _authController.loginEmailController,
              label: "Email",
              icon: Icons.email,
              isPassword: false,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Password input field
            _buildInputField(
              controller: _authController.loginPasswordController,
              label: "Password",
              icon: Icons.lock,
              isPassword: !_isPasswordVisible,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                return null;
              },
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white70,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Login button
            Obx(() => _authService.isLoading.value
                ? const CircularProgressIndicator(color: Colors.deepPurple)
                : ElevatedButton(
                    onPressed: _authController.login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                    ),
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )),
            const SizedBox(height: 16),
            
            // Sign Up prompt
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account? ",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: widget.onSwitchToSignUp,
                  child: const Text(
                    "Sign Up",
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required bool isPassword,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white),
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.normal,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          prefixIcon: Icon(icon, color: Colors.white),
          suffixIcon: suffixIcon,
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white70),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white, width: 2),
          ),
          errorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.redAccent, width: 2),
          ),
          errorStyle: const TextStyle(color: Colors.redAccent),
        ),
      ),
    );
  }
}