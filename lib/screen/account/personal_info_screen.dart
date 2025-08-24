 
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chewata/controller/account_controller.dart';
import 'package:google_fonts/google_fonts.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({Key? key}) : super(key: key);

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final AccountController controller = Get.find<AccountController>();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    // Ensure user data is available once when screen opens
    if (controller.user.value == null && !controller.isLoading.value) {
      controller.loadUserData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title:   Text('Personal Information' , style: GoogleFonts.ubuntu()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SafeArea(
           child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  _sectionCard(
                    context: context,
                    title: 'Profile Information',
                    icon: Icons.person_outline,
                    child: Column(
                    children: [
                      TextFormField(
                      controller: controller.fullNameController,
                      enabled: !controller.isUpdating.value,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      style: GoogleFonts.ubuntu(),
                      decoration: _inputDecoration(
                        context,
                        label: 'Full Name',
                        hint: 'Enter your full name',
                        icon: Icons.person,
                      ).copyWith(
                        labelStyle: GoogleFonts.ubuntu(),
                        hintStyle: GoogleFonts.ubuntu(),
                      ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                      controller: controller.birthDateController,
                      readOnly: true,
                      onTap: () => _selectDate(context, controller),
                      style: GoogleFonts.ubuntu(),
                      decoration: _inputDecoration(
                        context,
                        label: 'Birth Date',
                        hint: 'Select your birth date',
                        icon: Icons.cake_outlined,
                        suffix: const Icon(Icons.calendar_today, size: 18),
                      ).copyWith(
                        labelStyle: GoogleFonts.ubuntu(),
                        hintStyle: GoogleFonts.ubuntu(),
                      ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                          controller.isUpdating.value
                            ? null
                            : () => controller.updatePersonalInfo(),
                        icon:
                          controller.isUpdating.value
                            ? SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.onPrimary,
                              ),
                            ),
                            )
                            : const Icon(Icons.save_outlined),
                        label: Text('Save Changes', style: GoogleFonts.ubuntu()),
                        style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        ),
                      ),
                      ),
                    ],
                    ),
                  ),   const SizedBox(height: 20),

                _sectionCard(
                  context: context,
                  title: 'Change Password',
                  icon: Icons.lock_outline,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: controller.currentPasswordController,
                        enabled: !controller.isUpdating.value,
                        obscureText: _obscureCurrent,
                        decoration: _inputDecoration(
                          context,
                          label: 'Current Password',
                          hint: 'Enter your current password',
                          icon: Icons.lock,
                          suffix: IconButton(
                            tooltip:
                                _obscureCurrent
                                    ? 'Show password'
                                    : 'Hide password',
                            icon: Icon(
                              _obscureCurrent
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed:
                                () => setState(() {
                                  _obscureCurrent = !_obscureCurrent;
                                }),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: controller.newPasswordController,
                        enabled: !controller.isUpdating.value,
                        obscureText: _obscureNew,
                        decoration: _inputDecoration(
                          context,
                          label: 'New Password',
                          hint: 'Enter your new password',
                          icon: Icons.lock_outline,
                          suffix: IconButton(
                            tooltip:
                                _obscureNew ? 'Show password' : 'Hide password',
                            icon: Icon(
                              _obscureNew
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed:
                                () => setState(() {
                                  _obscureNew = !_obscureNew;
                                }),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: controller.confirmPasswordController,
                        enabled: !controller.isUpdating.value,
                        obscureText: _obscureConfirm,
                        decoration: _inputDecoration(
                          context,
                          label: 'Confirm New Password',
                          hint: 'Re-enter your new password',
                          icon: Icons.lock_reset,
                          suffix: IconButton(
                            tooltip:
                                _obscureConfirm
                                    ? 'Show password'
                                    : 'Hide password',
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed:
                                () => setState(() {
                                  _obscureConfirm = !_obscureConfirm;
                                }),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              controller.isUpdating.value
                                  ? null
                                  : () => controller.updatePassword(),
                          icon:
                              controller.isUpdating.value
                                  ? SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        theme.colorScheme.onPrimary,
                                      ),
                                    ),
                                  )
                                  : const Icon(Icons.password_outlined),
                          label: const Text('Change Password'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // Shared input decoration to keep a consistent look
  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: theme.colorScheme.surface.withOpacity(0.3),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _sectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
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
      lastDate: DateTime(now.year - 13, now.month, now.day), // Min age 13
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary,
              onPrimary: theme.colorScheme.onPrimary,
              onSurface: theme.colorScheme.onSurface,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
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
