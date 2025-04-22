// lib/controller/auth_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chewata/services/auth_service.dart';

class AuthController extends GetxController {
  // Singleton instance
  static AuthController get instance => Get.find();
  
  // Form controllers for login
  final TextEditingController loginEmailController = TextEditingController();
  final TextEditingController loginPasswordController = TextEditingController();
  
  // Form controllers for signup
  final TextEditingController signupFullNameController = TextEditingController();
  final TextEditingController signupEmailController = TextEditingController();
  final TextEditingController signupBirthDateController = TextEditingController();
  final TextEditingController signupPasswordController = TextEditingController();
  final TextEditingController signupConfirmPasswordController = TextEditingController();
  
  // Form keys
  final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();
  
  // Selected birthdate
  Rx<DateTime?> selectedBirthDate = Rx<DateTime?>(null);
  
  // Auth service
  final AuthService _authService = AuthService.instance;
  
  // Handle login
  Future<void> login() async {
    if (loginFormKey.currentState!.validate()) {
      final userCredential = await _authService.loginWithEmailAndPassword(
        email: loginEmailController.text.trim(),
        password: loginPasswordController.text.trim(),
      );
      
      if (userCredential != null) {
        // Successfully logged in
        Get.offAllNamed('/home');
      }
    }
  }
  
  // Handle signup
  Future<void> signup() async {
    if (signupFormKey.currentState!.validate() && selectedBirthDate.value != null) {
      final userCredential = await _authService.signUpWithEmailAndPassword(
        email: signupEmailController.text.trim(),
        password: signupPasswordController.text.trim(),
        fullName: signupFullNameController.text.trim(),
        birthDate: selectedBirthDate.value!,
      );
      
      if (userCredential != null) {
        // Successfully signed up
        Get.offAllNamed('/home');
      }
    } else if (selectedBirthDate.value == null) {
      Get.snackbar('Error', 'Please select your birth date');
    }
  }
  
  // Set selected birth date
  void setSelectedBirthDate(DateTime date) {
    selectedBirthDate.value = date;
    signupBirthDateController.text = "${date.day}/${date.month}/${date.year}";
  }
  
  @override
  void onClose() {
    // Dispose all controllers
    loginEmailController.dispose();
    loginPasswordController.dispose();
    signupFullNameController.dispose();
    signupEmailController.dispose();
    signupBirthDateController.dispose();
    signupPasswordController.dispose();
    signupConfirmPasswordController.dispose();
    super.onClose();
  }
}