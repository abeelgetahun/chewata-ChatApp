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

class _SignupFormState extends State<SignupForm>
    with SingleTickerProviderStateMixin {
  final AuthController _authController = Get.find<AuthController>();
  final AuthService _authService = Get.find<AuthService>();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isPasswordTouched = false;
  bool _isPasswordValid = false;

  // Animation controller for password validation text
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Listen to password changes to update validation state
    _authController.signupPasswordController.addListener(_validatePassword);
  }

  void _validatePassword() {
    final password = _authController.signupPasswordController.text;

    if (password.isNotEmpty && !_isPasswordTouched) {
      setState(() => _isPasswordTouched = true);
    }

    final wasValid = _isPasswordValid;
    final isNowValid = password.length >= 6;

    if (wasValid != isNowValid) {
      setState(() => _isPasswordValid = isNowValid);

      if (isNowValid) {
        // If now valid, start fade out animation
        _animationController.forward();
      } else {
        // If not valid, make helper text visible again
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _authController.signupPasswordController.removeListener(_validatePassword);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _authController.signupFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Create an Account",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(
                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                ).hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),

            // Birth Date input field
            _buildBirthDateField(),

            // Password input field with animated validation
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _authController.signupPasswordController,
                    obscureText: !_isPasswordVisible,
                    style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: "Password",
                      labelStyle: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.normal,
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                      prefixIcon: const Icon(Icons.lock, color: Colors.white),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
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
                        borderSide: BorderSide(
                          color: Colors.redAccent,
                          width: 2,
                        ),
                      ),
                      errorStyle: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                  if (_isPasswordTouched)
                    FadeTransition(
                      opacity: _opacityAnimation,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6, left: 12),
                        child: Text(
                          'At least 6 characters',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                _isPasswordValid
                                    ? Colors.green
                                    : Colors.redAccent,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Confirm Password input field
            _buildInputField(
              controller: _authController.signupConfirmPasswordController,
              label: "Confirm Password",
              icon: Icons.lock_outline,
              isPassword: !_isConfirmPasswordVisible,
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
                  _isConfirmPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.white70,
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
            Obx(
              () =>
                  _authService.isLoading.value
                      ? const CircularProgressIndicator(
                        color: Colors.deepPurple,
                      )
                      : ElevatedButton(
                        onPressed: _authController.signup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
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
                      ),
            ),

            const SizedBox(height: 16),

            // Login prompt
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Already have an account? ",
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                GestureDetector(
                  onTap: widget.onSwitchToLogin,
                  child: const Text(
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
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(color: Colors.white),
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
          helperText: helperText,
          helperStyle: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildBirthDateField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: _authController.signupBirthDateController,
        readOnly: true,
        onTap: () => _selectDate(context),
        style: const TextStyle(color: Colors.white),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select your birth date';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: "Birth Date",
          labelStyle: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.normal,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          prefixIcon: const Icon(Icons.calendar_today, color: Colors.white),
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
