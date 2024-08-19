import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:v_chat/screens/image_preview_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:v_chat/screens/profile_screen.dart';

class PostCard extends StatelessWidget {
  final String postId;
  final String title;
  final String content;
  final String postImage;
  final String songUrl;
  final String author;
  final List<dynamic> comments;
  final List<dynamic> likes;
  final bool containsImage;

  const PostCard({
    super.key,
    required this.postId,
    required this.title,
    required this.content,
    required this.postImage,
    required this.songUrl,
    required this.author,
    required this.containsImage,
    required this.comments,
    required this.likes,
  });

  Future<void> _addLike() async {
    try {
      final postSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('post_id', isEqualTo: postId)
          .get();

      if (postSnapshot.docs.isEmpty) {
        print('Post not found');
        return;
      }

      final post = postSnapshot.docs.first;

      final postLikes = post.data()['likes'];
      final List<dynamic> likesList;

      if (postLikes is List<dynamic>) {
        likesList = List<dynamic>.from(postLikes);
      } else {
        likesList = [];
      }

      final user = FirebaseAuth.instance.currentUser?.displayName;

      if (user == null) {
        print('User not logged in');
        return;
      }

      if (likesList.contains(user)) {
        likesList.remove(user);
      } else {
        likesList.add(user);
      }

      await post.reference.update({
        'likes': likesList,
      });
    } catch (e) {
      print('Error adding like: $e');
    }
  }

  Future<void> _deletePost() async {
    try {
      final postSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('post_id', isEqualTo: postId)
          .get();

      final post = postSnapshot.docs.first;

      if (containsImage) {
        final postImage = post.data()['post_image'];
        final imageId = post.data()['image_id'];

        if (postImage.isNotEmpty) {
          final storageRef = FirebaseStorage.instance.ref().child('post_images').child(imageId);
          await storageRef.delete();
        }
      }

      await post.reference.delete();
    } catch (e) {
      print('Error deleting post: $e');
    }
  }

  Future<void> _addComment(String commentText) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('posts').doc(postId).update({
          'comments': FieldValue.arrayUnion([
            {
              'author': user.displayName,
              'comment': commentText,
              'timestamp': DateTime.now(),
            },
          ]),
        });
      }
    } catch (e) {
      print('Error adding comment: $e');
    }
  }

  Future<String> _getProfilePictureUrl() async {
    try {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isEqualTo: author)
          .get();

      if (userSnapshot.docs.isEmpty) {
        return '';
      }

      final user = userSnapshot.docs.first;
      return user.data()['profilePictureUrl'];
    } catch (e) {
      print('Error getting profile picture URL: $e');
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController commentController = TextEditingController();
    return Card(
      child: Container(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8.0),
            Row(
              children: [
                FutureBuilder<String>(
                  future: _getProfilePictureUrl(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey,
                      );
                    }

                    if (snapshot.hasError) {
                      return const ImageIcon(
                        AssetImage('assets/icons/person.png'),
                        size: 30,
                      );
                    }
                    return CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(snapshot.data ?? ''),
                    );
                  },
                ),
                const SizedBox(width: 8.0),
                GestureDetector(
                  child: Text(
                    author,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(name: author),
                      ),
                    );
                  },
                ),
                if (FirebaseAuth.instance.currentUser?.displayName == author)
                  PopupMenuButton(
                    itemBuilder: (context) {
                      return [
                        PopupMenuItem(
                          child: Column(
                            children: [
                              ListTile(
                                leading: const ImageIcon(
                                  AssetImage('assets/icons/trash.png'),
                                ),
                                title: const Text('Delete'),
                                onTap: () {
                                  _deletePost();
                                  Navigator.of(context).pop();
                                },
                              ),
                              ListTile(
                                leading: const ImageIcon(
                                  AssetImage('assets/icons/edit.png'),
                                ),
                                title: const Text('Edit'),
                                onTap: () {
                                  // Edit the post
                                },
                              ),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
              ],
            ),
            const Divider(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8.0),
            if (containsImage)
              Center(
                child: GestureDetector(
                  child: Image.network(
                    postImage,
                    height: 300,
                    width: 300,
                    fit: BoxFit.fill,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ImagePreviewScreen(
                          imageUrl: postImage,
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (songUrl.isNotEmpty && songUrl != '')
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                height: 90,
                width: double.infinity,
                child: WebViewWidget(
                  controller: WebViewController()
                    ..setJavaScriptMode(JavaScriptMode.unrestricted)
                    ..loadRequest(Uri.parse(songUrl)),
                ),
              ),
            const SizedBox(height: 8.0),
            Text(
              content,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8.0),
            const Divider(),
            SizedBox(
              height: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _addLike,
                    child: likes.contains(FirebaseAuth.instance.currentUser?.displayName)
                        ? const ImageIcon(
                      AssetImage('assets/icons/heart.png'),
                      color: Colors.red,
                    )
                        : const ImageIcon(
                      AssetImage('assets/icons/heart.png'),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Text('${likes.length}'),
                  const SizedBox(width: 16.0),
                  GestureDetector(
                    child: const ImageIcon(
                      AssetImage('assets/icons/comment.png'),
                    ),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true, // Allows the bottom sheet to expand based on content
                        builder: (context) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min, // Adjusts the size based on content
                              children: [
                                Expanded(
                                    child: SingleChildScrollView(
                                      child: ListView.builder(
                                        itemCount: comments.length,
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemBuilder: (context, index) {
                                          final comment = comments[index];
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 8.0),
                                            padding: const EdgeInsets.all(12.0),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8.0),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.grey.withOpacity(0.2),
                                                  spreadRadius: 2,
                                                  blurRadius: 5,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  comment['author'] ?? 'Unknown author',
                                                  style: const TextStyle(
                                                    fontSize: 16.0,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                                const SizedBox(height: 4.0),
                                                Text(
                                                  comment['comment'] ?? 'No comment',
                                                  style: const TextStyle(
                                                    fontSize: 18.0,
                                                  ),
                                                ),
                                                const SizedBox(height: 4.0),
                                                Text(
                                                  comment['timestamp'].toDate().toString().split(' ')[0],
                                                  style: const TextStyle(
                                                    fontSize: 12.0,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: commentController,
                                        decoration: const InputDecoration(
                                          hintText: 'Enter your comment...',
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.send),
                                      onPressed: () {
                                        _addComment(commentController.text);
                                        commentController.clear();
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );

                    },
                  ),
                  const SizedBox(width: 8.0),
                  Text('${comments.length}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
