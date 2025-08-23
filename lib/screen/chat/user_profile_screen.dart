import 'package:chewata/models/user_model.dart';
import 'package:get/get.dart';
import 'package:chewata/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class UserProfileScreen extends StatelessWidget {
  final UserModel user;
  const UserProfileScreen({super.key, required this.user});

  String _calcAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'User Info',
          style: GoogleFonts.ubuntu(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundImage:
                  user.profilePicUrl.isNotEmpty
                      ? NetworkImage(user.profilePicUrl)
                      : null,
              child:
                  user.profilePicUrl.isEmpty
                      ? Text(
                        user.fullName.isNotEmpty
                            ? user.fullName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(fontSize: 32),
                      )
                      : null,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              user.fullName,
              style: GoogleFonts.ubuntu(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 28),
          _tile('Email', user.email, Icons.email_outlined),
          // Respect privacy: if user hides status or viewer hides their own,
          // show 'Offline'. We don't have direct access to viewer here, so we
          // assume AuthService via Get (optional), else fallback to target only.
          Builder(
            builder: (context) {
              try {
                final auth = Get.find<AuthService>();
                final viewerAllows =
                    auth.userModel.value?.showOnlineStatus ?? true;
                final targetAllows = user.showOnlineStatus;
                final visible = viewerAllows && targetAllows && user.isOnline;
                return _tile(
                  'Status',
                  visible ? 'Online' : 'Offline',
                  Icons.circle,
                );
              } catch (_) {
                // If dependencies not available here, fallback to target privacy only
                final visible = user.showOnlineStatus && user.isOnline;
                return _tile(
                  'Status',
                  visible ? 'Online' : 'Offline',
                  Icons.circle,
                );
              }
            },
          ),
          _tile('Age', _calcAge(user.birthDate), Icons.cake_outlined),
          _tile(
            'Joined',
            DateFormat.yMMMd().format(user.createdAt),
            Icons.calendar_today_outlined,
          ),
        ],
      ),
    );
  }

  Widget _tile(String title, String value, IconData icon) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: Icon(icon),
      title: Text(
        title,
        style: GoogleFonts.ubuntu(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(value, style: GoogleFonts.ubuntu()),
    );
  }
}
