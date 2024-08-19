import 'package:flutter/material.dart';
import 'package:v_chat/screens/theme_settings_screen.dart';
import 'profile_settings_screen.dart';
import 'notifications_screen.dart';
import 'privacy_policy_screen.dart';
import 'login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatelessWidget {

  final String userId;


  const SettingsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildHeader('Account'),
          _buildSettingsItem(
            icon: const ImageIcon(
              AssetImage('assets/icons/profile.png'),
              size: 35,
              color: Colors.black,
            ),
            title: 'Profile',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ProfileSettingsScreen(
                    userId: userId,
                  ),
                ),
              );
            },
          ),
          const Divider(),
          _buildHeader('Notifications'),
          _buildSettingsItem(
            icon: const ImageIcon(
                AssetImage('assets/icons/bell.png'),
              size: 35,
              color: Colors.black,
            ),
            title: 'Push Notifications',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
          const Divider(),
          _buildHeader('Privacy'),
          _buildSettingsItem(
            icon: const ImageIcon(
                AssetImage('assets/icons/lock.png'),
              size: 35,
              color: Colors.black,
            ),
            title: 'Privacy Policy',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
          const Divider(),
          _buildSettingsItem(
            icon: const ImageIcon(
                AssetImage('assets/icons/palette.png'),
              size: 35,
              color: Colors.black,
            ),
            title: 'Theme',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ThemeSettingsScreen()),
              );
            },
          ),
          const Divider(),
          _buildSettingsItem(
            icon: const ImageIcon(
                AssetImage('assets/icons/logout.png'),
              size: 35,
              color: Colors.black,
            ),
            title: 'Logout',
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required ImageIcon icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: icon,
      title: Text(title),
      onTap: onTap,
    );
  }

  void _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to log out.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
