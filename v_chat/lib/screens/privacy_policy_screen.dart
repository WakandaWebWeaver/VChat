import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VChat - Privacy Policy'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Privacy Policy & Data Usage',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Welcome to VChat!',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              const Text(
                'Signing up for a VChat Account requires you to have a valid Email Address and a Password.\n'
                  'You can also Sign-in via Google Authentication.\n',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Text(
                'Your personal information is not sold to third parties.\n',
                style: TextStyle(
                  fontSize: 16,
                  backgroundColor: Colors.red[50],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'By using VChat, you agree to the collection and use of information in accordance with this policy.\n',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomAppBar(
        color: Colors.teal,
        child: Padding(
          padding: EdgeInsets.all(5.0),
          child: Center(
            child: Text(
              'VChat By Esvin Joshua; 2024',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
          ),
        ),
      )
    );
  }
}
