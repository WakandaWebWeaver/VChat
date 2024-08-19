import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/settings_screen.dart';
import '../widgets/chat_preview.dart';
import 'chat_screen.dart';
import 'login_screen.dart';

class ChatListScreen extends StatefulWidget {
  final String username;
  final String userId;
  final String chatId;

  const ChatListScreen({
    super.key,
    required this.username,
    required this.userId,
    required this.chatId,
  });

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _storage = const FlutterSecureStorage();
  String? _backgroundImagePath;

  @override
  void initState() {
    super.initState();
    _loadBackgroundImage();
  }

  Future<void> _loadBackgroundImage() async {
    final storedBackground = await _storage.read(key: 'chatListBackground');
    setState(() {
      _backgroundImagePath = storedBackground;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VChat - Messages'),
        backgroundColor: Colors.teal,
        actions: [
          PopupMenuButton<String>(
            icon: const ImageIcon(
              AssetImage(
                  'assets/icons/menu.png',
              ),
              color: Colors.white,
              size: 30,
      ),
            onSelected: (value) {
              if (value == 'addChat') {
                _showUserSelectionDialog(context);
              } else if (value == 'logout') {
                _logout(context);
              } else if (value == 'settings') {
                _navigateToSettings(context);
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'addChat',
                  child: Row(
                    children: [
                      ImageIcon(
                        AssetImage('assets/icons/plus.png'),
                        size: 30,
                        color: Colors.black,
                      ),
                      SizedBox(width: 8),
                      Text('Start New Chat'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      ImageIcon(
                        AssetImage('assets/icons/logout.png'),
                        size: 30,
                        color: Colors.black,
                      ),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'settings',
                  child: Row(
                    children: [
                      ImageIcon(
                        AssetImage('assets/icons/settings.png'),
                        size: 30,
                        color: Colors.black,
                      ),
                      SizedBox(width: 8),
                      Text('Settings'),
                    ],
                  ),
                ),
              ];
            },
            position: PopupMenuPosition.under,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: _backgroundImagePath != null
              ? DecorationImage(
            image: AssetImage(_backgroundImagePath!),
            fit: BoxFit.cover,
          )
              : null,
          color: _backgroundImagePath == null ? Colors.white : null,
        ),
        child: Flex(
          direction: Axis.vertical,
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection(widget.userId)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                        child: Text(
                            'Fell off trying to fetch chats. ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(20),
                            child: Image.asset(
                              'assets/images/app_logo_transparent.png',
                              width: 100,
                              height: 100,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Start a new chat by tapping the ',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              Icon(
                                Icons.menu,
                              ),
                              Text(
                                ' icon.',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  }

                  try {
                    final chatDocs = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: chatDocs.length,
                      itemBuilder: (context, index) {
                        final chatDoc = chatDocs[index];
                        final chatId = chatDoc['messageId'];
                        final title = chatDoc['title'];
                        final lastMessage = chatDoc['lastMessage'];
                        final timestamp = chatDoc['timestamp'];
                        final recipientDocId = chatDoc['recipientDocId'];

                        return ChatPreview(
                          chatId: chatId,
                          recieverName: title,
                          currentName: widget.username,
                          lastMessage: lastMessage,
                          userId: widget.userId,
                          timestamp: timestamp,
                          recipientDocId: recipientDocId,
                          readStatus: chatDoc['read'] ?? false,
                        );
                      },
                    );
                  } catch (e) {
                    return Center(child: Text('Failed to fetch chats. $e'));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserSelectionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Start A New Chat',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const Divider(),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Failed to fetch users. ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }

                final userDocs = snapshot.data!.docs;
                return Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: userDocs.length,
                    itemBuilder: (context, index) {
                      final userDoc = userDocs[index];
                      final username = userDoc['name'];
                      final profilePictureUrl = userDoc['profilePictureUrl'] ?? '';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(profilePictureUrl),
                        ),
                        title: Text(username),
                        onTap: () {
                          Navigator.of(context).pop();
                          _checkAndStartNewChat(context, username);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          userId: widget.userId,
        ),
      ),
    );
  }

  Future<void> _checkAndStartNewChat(BuildContext context, String recipientUsername) async {
    final chatIdPartOne = (widget.userId.hashCode ^ recipientUsername.hashCode ^ Timestamp.now().hashCode);
    final chatIdPartTwo = DateTime.now().millisecondsSinceEpoch.toRadixString(32);
    final chatIdPartThree = Random().nextInt(9999999);

    final chatId = (chatIdPartOne.toString() + chatIdPartTwo.toString() + chatIdPartThree.toString()) * 2;

    final chatExists = await _checkChatExists(recipientUsername);

    if (!chatExists) {
      await FirebaseFirestore.instance.collection(widget.userId).doc(chatId).set({
        'title': recipientUsername,
        'lastMessage': 'Chat started',
        'timestamp': Timestamp.now(),
        'messageId': chatId,
        'recipientDocId': await _getRecipientDocId(recipientUsername),
        'read': true,
        'profilePictureUrl': 'https://firebasestorage.googleapis.com/v0/b/chat-room-ba49a.appspot.com/o/profile_media%2Fdefault_male_2.jpg?alt=media&token=82f361f4-171c-4918-b182-15ee98607c09',
      });

      final recipientDoc = await (FirebaseFirestore.instance.collection('users').where('name', isEqualTo: recipientUsername).get()) as QuerySnapshot;
      final String recipientDocId = recipientDoc.docs.first['userId'];

      await FirebaseFirestore.instance.collection(recipientDocId).doc(chatId).set({
        'title': widget.username,
        'lastMessage': 'Chat started',
        'timestamp': Timestamp.now(),
        'messageId': chatId,
        'recipientDocId': widget.userId,
        'read': false,
        'profilePictureUrl': 'https://firebasestorage.googleapis.com/v0/b/chat-room-ba49a.appspot.com/o/profile_media%2Fdefault_male_2.jpg?alt=media&token=82f361f4-171c-4918-b182-15ee98607c09',
      });

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatId,
            username: recipientUsername,
            currentUserId: widget.userId,
            recipientDocId: recipientDocId,
            recipientName: recipientUsername,
          ),
        ),
      );
    }
  }

  Future<bool> _checkChatExists(String recipientUsername) async {
    final userChats = await FirebaseFirestore.instance.collection(widget.userId).get();
    final recipientChats = await FirebaseFirestore.instance.collection(await _getRecipientDocId(recipientUsername)).get();
    return userChats.docs.any((doc) => doc['title'] == recipientUsername) ||
        recipientChats.docs.any((doc) => doc['title'] == widget.username);
  }

  Future<String> _getRecipientDocId(String recipientUsername) async {
    final recipientDoc = await FirebaseFirestore.instance.collection('users').where('name', isEqualTo: recipientUsername).get();
    return recipientDoc.docs.first['userId'];
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    await _storage.deleteAll();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }
}
