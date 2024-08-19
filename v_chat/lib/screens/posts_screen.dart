import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:v_chat/screens/create_post_screen.dart';
import 'package:v_chat/widgets/post_card.dart';
import 'package:v_chat/services/spotify_service.dart';

class PostsScreen extends StatelessWidget {
  const PostsScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final spotifyService = SpotifyService();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CreatePostScreen(
                    userName: FirebaseAuth.instance.currentUser!.displayName!,
                  ),
                ),
              );
            },
            child: const ImageIcon(
              AssetImage('assets/icons/plus.png'),
            ),
          ),
        ],
      ),
      appBar: AppBar(
        title: const Text('VChat - Posts'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('posts').orderBy('post_id', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No Posts"
              )
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final posts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return PostCard(
                postId: post['post_id'],
                title: post['title'],
                content: post['content'],
                postImage: post['post_image'],
                songUrl: post['song_url'],
                author: post['author'],
                containsImage: post['contains_image'],
                likes: post['likes'],
                comments: post['comments'],
              );
            },
          );
        },
      ),
    );
  }
}
