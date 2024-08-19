import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:v_chat/screens/image_preview_screen.dart';
import 'package:v_chat/screens/profile_settings_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ProfileScreen extends StatelessWidget {
  final String name;

  const ProfileScreen({
    super.key,
    required this.name,
  });

  Future<Map<String, dynamic>> _fetchUserData() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .where('name', isEqualTo: name)
        .limit(1)
        .get();

    if (userDoc.docs.isEmpty) {
      throw Exception('User not found');
    }

    return userDoc.docs.first.data();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VChat - Profile'),
        backgroundColor: Colors.teal,
        actions: [
          if (FirebaseAuth.instance.currentUser!.displayName == name)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ProfileSettingsScreen(
                      userId: FirebaseAuth.instance.currentUser!.uid,
                    )
                  ),
                );
              },
            ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final userData = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Picture
                Center(
                  child: GestureDetector(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(userData['profilePictureUrl'] ?? ''),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ImagePreviewScreen(
                            imageUrl: userData['profilePictureUrl'],
                          ),
                        ),
                      );
                    },
                  )
                ),
                const SizedBox(height: 16.0),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8.0),
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
                            ..loadRequest(Uri.parse(
                              "${userData['profile_song']}",
                            ))
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16.0),

                Text(
                  userData['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),

                // Username
                Text(
                  '@${userData['username'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16.0),

                // Bio
                Text(
                  userData['bio'] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16.0),
              ],
            ),
          );
        },
      ),
    );
  }
}
