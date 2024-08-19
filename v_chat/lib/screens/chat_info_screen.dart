import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../screens/image_preview_screen.dart';

class ChatInfoScreen extends StatefulWidget {
  final String chatId;
  final String recipientUserName;
  final String mediaPath;

  const ChatInfoScreen({
    super.key,
    required this.chatId,
    required this.recipientUserName,
    required this.mediaPath,
  });

  @override
  _ChatInfoScreenState createState() => _ChatInfoScreenState();
}

class _ChatInfoScreenState extends State<ChatInfoScreen> with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _chatInfo;
  late Future<List<Map<String, dynamic>>> _mediaFiles;
  late Future<String?> _profilePictureUrl;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _chatInfo = _fetchChatInfo();
    _mediaFiles = _fetchMediaFiles();
    _profilePictureUrl = _fetchProfilePictureUrl();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<Map<String, dynamic>> _fetchChatInfo() async {
    try {
      final chatDoc = await FirebaseFirestore.instance.collection(widget.chatId).doc().get();
      if (chatDoc.exists) {
        return {
          'chatId': chatDoc.id,
          'messages': chatDoc.data()?['messages'] ?? [],
        };
      }
      return {'chatId': widget.chatId, 'messages': []};
    } catch (e) {
      print("Error fetching chat info: $e");
      return {'chatId': widget.chatId, 'messages': []};
    }
  }

  Future<List<Map<String, dynamic>>> _fetchMediaFiles() async {
    List<Map<String, dynamic>> mediaFiles = [];

    try {
      final storageRef = FirebaseStorage.instance.ref().child(widget.mediaPath);
      final ListResult result = await storageRef.listAll();

      for (var item in result.items) {
        final String url = await item.getDownloadURL();
        final FullMetadata metadata = await item.getMetadata();
        final String name = metadata.name;
        final String type = metadata.contentType?.split('/').first ?? 'Unknown';
        final String sizeBytes = metadata.size.toString();
        final String size = (int.parse(sizeBytes) / (1024 * 1024)).toStringAsFixed(2);

        mediaFiles.add({
          'url': url,
          'name': name,
          'size': '$size MB',
          'type': type,
        });
      }
    } catch (e) {
      print("Error fetching media files: $e");
    }

    return mediaFiles;
  }

  Future<String?> _fetchProfilePictureUrl() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.recipientUserName)
          .get();

      return doc.data()?['profilePictureUrl'];
    } catch (e) {
      print("Error loading profile picture: $e");
      return null;
    }
  }

  Future<void> _pickAndUploadBackgroundImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      try {
        final file = await pickedFile.readAsBytes();
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('media/${widget.chatId}/background.jpg');
        await storageRef.putData(file);
        final url = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection(widget.chatId).doc('prefs').update({'background': url});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Background image updated successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print("Error uploading background image: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update background image.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Appbar displays recipient's username, the body has a TabBarView with three tabs for chat info, media, and settings.
      appBar: AppBar(
        title: Text(widget.recipientUserName),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _chatInfo,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final chatInfo = snapshot.data;
            return Column(
              children: [
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildChatInfo(chatInfo!),
                      _buildMedia(),
                      _buildSettings(),
                    ],
                  ),
                ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(text: 'Chat Info'),
        Tab(text: 'Media'),
        Tab(text: 'Settings'),
      ],
    );
  }

  Widget _buildChatInfo(Map<String, dynamic> chatInfo) {
    final int messageCount = chatInfo['messages'].length;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionHeader('Chat Info'),
        ListTile(
          title: const Text('Number of Messages'),
          trailing: Text(messageCount.toString()),
        ),
      ],
    );
  }

  Widget _buildMedia() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _mediaFiles,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final mediaFiles = snapshot.data;
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4.0,
              mainAxisSpacing: 4.0,
            ),
            itemCount: mediaFiles?.length,
            itemBuilder: (context, index) {
              final media = mediaFiles?[index];
              return _buildMediaItem(media!);
            },
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildSettings() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionHeader('Settings'),
        ListTile(
          title: const Text('Set Background'),
          onTap: _pickAndUploadBackgroundImage,
        ),
      ],
    );
  }


  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey[200],
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMediaItem(Map<String, dynamic> media) {
    final String url = media['url'];
    final String name = media['name'];
    final String size = media['size'];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImagePreviewScreen(
              imageUrl: url,
            ),
          ),
        );
      },
      child: GridTile(
        footer: GridTileBar(
          backgroundColor: Colors.black54,
          title: Text(name),
          subtitle: Text(size),
        ),
        child: Image.network(
          url,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Future<int> _getNumberOfMessages(String chatId) async {
    try {
      final chatCollection = FirebaseFirestore.instance.collection(chatId);
      final messages = await chatCollection.get();
      return messages.size;
    } catch (e) {
      print("Error fetching number of messages: $e");
      return 0;
    }
  }
}
