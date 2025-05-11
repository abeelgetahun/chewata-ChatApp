import 'package:flutter/material.dart';

class TermsAndPrivacyScreen extends StatefulWidget {
  @override
  _TermsAndPrivacyScreenState createState() => _TermsAndPrivacyScreenState();
}

class _TermsAndPrivacyScreenState extends State<TermsAndPrivacyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Privacy'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).primaryColor,
          labelColor: isDarkMode ? Colors.white : Colors.black,
          tabs: const [
            Tab(text: 'Terms of Service'),
            Tab(text: 'Privacy Policy'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTermsOfService(isDarkMode),
          _buildPrivacyPolicy(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildTermsOfService(bool isDarkMode) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Terms of Service', isDarkMode),
          _buildLastUpdated('Last updated: May 1, 2023', isDarkMode),
          _buildParagraph(
            'Welcome to Chewata. By accessing or using our mobile application, you agree to be bound by these Terms of Service.',
            isDarkMode,
          ),
          _buildSectionSubtitle('1. Acceptance of Terms', isDarkMode),
          _buildParagraph(
            'By accessing and using Chewata, you acknowledge that you have read, understood, and agree to be bound by these Terms. If you do not agree with these Terms, please do not use our application.',
            isDarkMode,
          ),
          _buildSectionSubtitle('2. Changes to Terms', isDarkMode),
          _buildParagraph(
            'We reserve the right to modify these Terms at any time. We will provide notice of any material changes by updating the "Last Updated" date at the top of these Terms. Your continued use of Chewata after such modifications will constitute your acknowledgment of the modified Terms.',
            isDarkMode,
          ),
          _buildSectionSubtitle('3. User Accounts', isDarkMode),
          _buildParagraph(
            'When you create an account with us, you must provide accurate and complete information. You are solely responsible for the activity that occurs on your account, and you must keep your account password secure.',
            isDarkMode,
          ),
          _buildSectionSubtitle('4. User Content', isDarkMode),
          _buildParagraph(
            'Our application may allow you to post, link, store, share and otherwise make available certain information, text, graphics, videos, or other material. You are responsible for the content you post to the application.',
            isDarkMode,
          ),
          _buildSectionSubtitle('5. Termination', isDarkMode),
          _buildParagraph(
            'We may terminate or suspend your account immediately, without prior notice or liability, for any reason whatsoever, including without limitation if you breach the Terms.',
            isDarkMode,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPrivacyPolicy(bool isDarkMode) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Privacy Policy', isDarkMode),
          _buildLastUpdated('Last updated: May 1, 2023', isDarkMode),
          _buildParagraph(
            'This Privacy Policy describes how Chewata collects, uses, and discloses your personal information when you use our mobile application.',
            isDarkMode,
          ),
          _buildSectionSubtitle('1. Information We Collect', isDarkMode),
          _buildParagraph(
            'We collect information that you provide directly to us, such as when you create an account, update your profile, use interactive features, participate in contests, promotions, or surveys, request customer support, or otherwise communicate with us.',
            isDarkMode,
          ),
          _buildSectionSubtitle('2. How We Use Your Information', isDarkMode),
          _buildParagraph(
            'We use the information we collect to provide, maintain, and improve our services, to develop new features, to protect Chewata and our users, and for other purposes described in this Privacy Policy.',
            isDarkMode,
          ),
          _buildSectionSubtitle('3. Sharing of Information', isDarkMode),
          _buildParagraph(
            'We may share information about you as follows or as otherwise described in this Privacy Policy: with vendors, consultants, and other service providers who need access to such information to carry out work on our behalf.',
            isDarkMode,
          ),
          _buildSectionSubtitle('4. Data Security', isDarkMode),
          _buildParagraph(
            'We take reasonable measures to help protect information about you from loss, theft, misuse, unauthorized access, disclosure, alteration, and destruction.',
            isDarkMode,
          ),
          _buildSectionSubtitle('5. Your Choices', isDarkMode),
          _buildParagraph(
            'You may update, correct, or delete your account information at any time by logging into your account. If you wish to delete your account, please contact us.',
            isDarkMode,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildLastUpdated(String text, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontStyle: FontStyle.italic,
          color: isDarkMode ? Colors.white60 : Colors.black54,
        ),
      ),
    );
  }

  Widget _buildSectionSubtitle(String title, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          height: 1.5,
          color: isDarkMode ? Colors.white70 : Colors.black87,
        ),
      ),
    );
  }
}
