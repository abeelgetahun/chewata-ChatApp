import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chewata/utils/theme/app_theme.dart';

class HelpCenterScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Help Center'), elevation: 0),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFAQSection(context, isDarkMode),
              const SizedBox(height: 24),
              _buildTutorialSection(context, isDarkMode),
              const SizedBox(height: 24),
              _buildSupportSection(context, isDarkMode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQSection(BuildContext context, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequently Asked Questions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        _buildExpandableFAQ(
          context,
          'How do I create an account?',
          'You can create an account by tapping on the "Sign Up" button on the login screen and following the instructions.',
          isDarkMode,
        ),
        _buildExpandableFAQ(
          context,
          'How can I reset my password?',
          'You can reset your password by tapping on "Forgot Password" on the login screen and following the instructions sent to your email.',
          isDarkMode,
        ),
        _buildExpandableFAQ(
          context,
          'Is my data secure?',
          'Yes, we use industry-standard encryption to protect your data. Your privacy is our top priority.',
          isDarkMode,
        ),
        _buildExpandableFAQ(
          context,
          'How do I delete my account?',
          'You can delete your account from the Personal Information section in your account settings.',
          isDarkMode,
        ),
      ],
    );
  }

  Widget _buildExpandableFAQ(
    BuildContext context,
    String question,
    String answer,
    bool isDarkMode,
  ) {
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
      child: ExpansionTile(
        title: Text(
          question,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
        ],
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        childrenPadding: EdgeInsets.zero,
        expandedAlignment: Alignment.topLeft,
      ),
    );
  }

  Widget _buildTutorialSection(BuildContext context, bool isDarkMode) {
    final List<Map<String, String>> tutorials = [
      {
        'title': 'Getting Started',
        'description': 'Learn the basics of using Chewata',
      },
      {
        'title': 'Advanced Features',
        'description': 'Discover all the powerful features',
      },
      {
        'title': 'Tips & Tricks',
        'description': 'Become a power user with these tips',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Video Tutorials',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        ...tutorials.map(
          (tutorial) => _buildTutorialItem(
            context,
            tutorial['title']!,
            tutorial['description']!,
            isDarkMode,
          ),
        ),
      ],
    );
  }

  Widget _buildTutorialItem(
    BuildContext context,
    String title,
    String description,
    bool isDarkMode,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.play_circle_outline,
            color: Theme.of(context).primaryColor,
            size: 30,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            description,
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
        onTap: () {
          // Play tutorial video
          Get.snackbar(
            'Coming Soon',
            'Video tutorials will be available in the next update',
            snackPosition: SnackPosition.BOTTOM,
          );
        },
      ),
    );
  }

  Widget _buildSupportSection(BuildContext context, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Still Need Help?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
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
            children: [
              Text(
                'Our support team is ready to assist you with any questions or issues you may have.',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
