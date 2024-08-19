import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:v_chat/screens/chat_list_screen.dart';
import 'package:v_chat/screens/create_post_screen.dart';
import 'package:v_chat/screens/posts_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        children: [
          CreatePostScreen(
            userName: FirebaseAuth.instance.currentUser!.displayName!,
          ),
          const PostsScreen(),
          ChatListScreen(
            userId: FirebaseAuth.instance.currentUser!.uid,
            username: FirebaseAuth.instance.currentUser!.displayName!,
            chatId: FirebaseAuth.instance.currentUser!.email!,
          ),
        ],
      ),
    );
  }
}