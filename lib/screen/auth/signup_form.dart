// lib/screen/auth/signup_form.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chewata/controller/auth_controller.dart';
import 'package:chewata/services/auth_service.dart';

class SignupForm extends StatefulWidget {
  final VoidCallback onSwitchToLogin;

  const SignupForm({super.key, required this.onSwitchToLogin});

  @override
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> with SingleTickerProviderStateMixin {
  final AuthController _authController = Get.find<AuthController>();
  final AuthService _authService = Get.find<AuthService>();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    // Determine the current theme mode (light or dark)
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Set text color based on the theme mode
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return SingleChildScrollView(
      child: Form(
        key: _authController.signupFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Create an Account",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textColor,
                fontFamily: "Poppins",
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Full Name input field
            _buildInputField(
              controller: _authController.signupFullNameController,
              label: "Full Name",
              icon: Icons.person,
              isPassword: false,
              textColor: textColor,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your full name';
                }
                if (value.length < 4) {
                  return 'Name must be at least 4 characters';
                }
                return null;
              },
            ),

            // Email input field
            _buildInputField(
              controller: _authController.signupEmailController,
              label: "Email",
              icon: Icons.email,
              isPassword: false,
              textColor: textColor,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),

            // Birth Date input field
            _buildBirthDateField(textColor),

            // Password input field
            _buildInputField(
              controller: _authController.signupPasswordController,
              label: "Password",
              icon: Icons.lock,
              isPassword: !_isPasswordVisible,
              textColor: textColor,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),

            // Confirm Password input field
            _buildInputField(
              controller: _authController.signupConfirmPasswordController,
              label: "Confirm Password",
              icon: Icons.lock_outline,
              isPassword: !_isConfirmPasswordVisible,
              textColor: textColor,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _authController.signupPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
            ),

            const SizedBox(height: 24),

            // Sign Up button
            Obx(() => _authService.isLoading.value
                ? const CircularProgressIndicator(color: Colors.deepPurple)
                : ElevatedButton(
                    onPressed: _authController.signup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                    ),
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )),

            const SizedBox(height: 16),

            // Login prompt
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Already have an account? ",
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: widget.onSwitchToLogin,
                  child: Text(
                    "Login",
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
    required Color textColor,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(color: textColor), // Text color dynamically set
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: textColor.withOpacity(0.7), // Label text color dynamically set
            fontWeight: FontWeight.normal,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          prefixIcon: Icon(icon, color: textColor), // Icon color dynamically set
          suffixIcon: suffixIcon,
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey), // Keep border color unchanged
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.deepPurple, width: 2), // Keep border color unchanged
          ),
          errorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.redAccent), // Keep error border color unchanged
          ),
          focusedErrorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.redAccent, width: 2), // Keep error border color unchanged
          ),
          errorStyle: const TextStyle(color: Colors.redAccent), // Keep error text color unchanged
        ),
      ),
    );
  }

  Widget _buildBirthDateField(Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: _authController.signupBirthDateController,
        readOnly: true,
        onTap: () => _selectDate(context),
        style: TextStyle(color: textColor), // Text color dynamically set
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select your birth date';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: "Birth Date",
          labelStyle: TextStyle(
            color: textColor.withOpacity(0.7), // Label text color dynamically set
            fontWeight: FontWeight.normal,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          prefixIcon: Icon(Icons.calendar_today, color: textColor), // Icon color dynamically set
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey), // Keep border color unchanged
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.deepPurple, width: 2), // Keep border color unchanged
          ),
          errorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.redAccent), // Keep error border color unchanged
          ),
          focusedErrorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.redAccent, width: 2), // Keep error border color unchanged
          ),
          errorStyle: const TextStyle(color: Colors.redAccent), // Keep error text color unchanged
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
              surface: Color(0xFF303030),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _authController.setSelectedBirthDate(picked);
    }
  }
}