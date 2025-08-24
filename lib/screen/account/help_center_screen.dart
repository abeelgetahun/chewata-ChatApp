import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chewata/screen/chat/search_screen.dart';
import 'package:chewata/screen/connect_screen.dart';
import 'package:chewata/screen/fun_screen.dart';
import 'package:chewata/screen/account/personal_info_screen.dart';
import 'package:chewata/screen/account/terms_and_privacy_screen.dart';
import 'package:chewata/screen/account/about_app_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpCenterScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Help Center', style: GoogleFonts.ubuntu()),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIntroSection(context, isDarkMode),
              const SizedBox(height: 24),
              _buildQuickActions(context, isDarkMode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroSection(BuildContext context, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to Chewata Help Center',
            style: GoogleFonts.ubuntu(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chewata is a cross-platform chat and social app. Here you\'ll find tips for messaging 1-to-1 or in groups, making random connections, managing privacy and notifications, and customizing themes across Android, iOS, Web, and Desktop.',
            style: GoogleFonts.ubuntu(
              height: 1.45,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        _navTile(
          context,
          icon: Icons.person_outline,
          title: 'Edit Personal Information',
          subtitle: 'Update your name and birth date',
          isDarkMode: isDarkMode,
          onTap: () => Get.to(() => const PersonalInfoScreen()),
        ),
        _navTile(
          context,
          icon: Icons.search,
          title: 'Search Users',
          subtitle: 'Find and start a 1-to-1 chat',
          isDarkMode: isDarkMode,
          onTap: () => Get.to(() => SearchScreen()),
        ),
      ],
    );
  }

  Widget _navTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.15),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(
          title,
          style: GoogleFonts.ubuntu(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.ubuntu(
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isDarkMode ? Colors.white54 : Colors.black45,
        ),
      ),
    );
  }

  Widget _buildTipCard(
    BuildContext context,
    bool isDarkMode, {
    required String title,
    required String body,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
