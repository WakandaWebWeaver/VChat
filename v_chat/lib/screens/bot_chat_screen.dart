import 'package:flutter/material.dart';

class BotChatScreen extends StatelessWidget {

  const BotChatScreen({super.key});

  // TODO: Implement a bot chat Screen. Path: functions/index.js

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bot Chat'),
      ),
      body: const Center(
        child: Text('Bot Chat Screen'),
      ),
    );
  }
}