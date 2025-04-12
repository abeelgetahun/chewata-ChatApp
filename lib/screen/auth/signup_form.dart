import 'package:flutter/material.dart';

class SignupForm extends StatelessWidget {
  final VoidCallback onSwitchToLogin;

  const SignupForm({super.key, required this.onSwitchToLogin});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView( // Wrap the content in a scrollable view
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
            label: "Full Name",
            icon: Icons.person,
            isPassword: false,
          ),

          // Username input field
          _buildInputField(
            label: "Username",
            icon: Icons.person_outline,
            isPassword: false,
          ),

          // Age input field
          _buildInputField(
            label: "Age",
            icon: Icons.calendar_today,
            isPassword: false,
            keyboardType: TextInputType.number,
          ),

          // Phone input field
          _buildInputField(
            label: "Phone",
            icon: Icons.phone,
            isPassword: false,
            keyboardType: TextInputType.phone,
          ),

          // Password input field
          _buildInputField(
            label: "Password",
            icon: Icons.lock,
            isPassword: true,
          ),

          const SizedBox(height: 24),

          // Sign Up button
          ElevatedButton(
            onPressed: () {
              // Handle sign up
            },
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
          ),

          const SizedBox(height: 16),

          // Login prompt
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Already have an account? ",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              GestureDetector(
                onTap: onSwitchToLogin,
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
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required bool isPassword,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.normal,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          prefixIcon: Icon(icon, color: Colors.white),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white70),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }
}