// lib/screen/account/personal_info_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chewata/controller/account_controller.dart';
import 'package:intl/intl.dart';

class PersonalInfoScreen extends StatelessWidget {
  const PersonalInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final AccountController controller = Get.find<AccountController>();

    // Make sure user data is loaded
    if (controller.user.value == null) {
      controller.loadUserData();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Information'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile information section
              _buildSectionTitle('Profile Information', isDarkMode),
              const SizedBox(height: 16),
              _buildProfileInfoSection(context, controller, isDarkMode),

              const SizedBox(height: 32),

              // Password change section
              _buildSectionTitle('Change Password', isDarkMode),
              const SizedBox(height: 16),
              _buildPasswordChangeSection(context, controller, isDarkMode),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildProfileInfoSection(
    BuildContext context,
    AccountController controller,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full Name Field
          _buildTextField(
            label: 'Full Name',
            controller: controller.fullNameController,
            hint: 'Enter your full name',
            icon: Icons.person,
            isDarkMode: isDarkMode,
          ),

          const SizedBox(height: 16),

          // Birth Date Field
          GestureDetector(
            onTap: () => _selectDate(context, controller),
            child: AbsorbPointer(
              child: _buildTextField(
                label: 'Birth Date',
                controller: controller.birthDateController,
                hint: 'Select your birth date',
                icon: Icons.calendar_today,
                isDarkMode: isDarkMode,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  controller.isUpdating.value
                      ? null
                      : () => controller.updatePersonalInfo(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child:
                  controller.isUpdating.value
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordChangeSection(
    BuildContext context,
    AccountController controller,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Password Field
          _buildTextField(
            label: 'Current Password',
            controller: controller.currentPasswordController,
            hint: 'Enter your current password',
            icon: Icons.lock,
            isDarkMode: isDarkMode,
            isPassword: true,
          ),

          const SizedBox(height: 16),

          // New Password Field
          _buildTextField(
            label: 'New Password',
            controller: controller.newPasswordController,
            hint: 'Enter your new password',
            icon: Icons.lock_outline,
            isDarkMode: isDarkMode,
            isPassword: true,
          ),

          const SizedBox(height: 16),

          // Confirm Password Field
          _buildTextField(
            label: 'Confirm New Password',
            controller: controller.confirmPasswordController,
            hint: 'Confirm your new password',
            icon: Icons.lock_reset,
            isDarkMode: isDarkMode,
            isPassword: true,
          ),

          const SizedBox(height: 24),

          // Change Password Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  controller.isUpdating.value
                      ? null
                      : () => controller.updatePassword(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child:
                  controller.isUpdating.value
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : const Text(
                        'Change Password',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDarkMode,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(Get.context!).primaryColor,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(
    BuildContext context,
    AccountController controller,
  ) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate =
        controller.selectedBirthDate.value ??
        DateTime(now.year - 18, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(
        now.year - 13,
        now.month,
        now.day,
      ), // Minimum age 13 years
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Theme.of(context).textTheme.bodyLarge!.color!,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.setSelectedBirthDate(picked);
    }
  }
}
