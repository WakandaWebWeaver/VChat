import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:v_chat/services/spotify_service.dart';

class CreatePostScreen extends StatefulWidget {
  final String userName;

  const CreatePostScreen({super.key, required this.userName});

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  String song_url = '';

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickSong() async {
    final spotifyService = SpotifyService();
    final List<Map<String, dynamic>> songs = [];

    Future<void> searchSongs(String query) async {
      final song = await spotifyService.searchSong(query);
      setState(() {
        if (!songs.any((s) => s['uri'] == song['uuri'])) {
          songs.add(song);
        }
            });
    }

    final selectedSong = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search for a song',
                  ),
                  onChanged: (query) {
                    if (query.isNotEmpty) {
                      searchSongs(query);
                    } else {
                      setState(() {
                        songs.clear();
                      });
                    }
                  },
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      return ListTile(
                        title: Text(song['name']),
                        subtitle: Text('${song['singer']}'),
                        onTap: () {
                          setState(() {
                            _contentController.text = '🎵 ${song['name']} by ${song['singer']}';
                            song_url = 'https://open.spotify.com/embed/track/${song['uri'].split(':').last}';
                          });
                          Navigator.of(context).pop(song);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (selectedSong != null) {
      // Handle any additional actions if necessary
    }
  }


  Future<void> _uploadPost() async {
    if (_isUploading) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final postIdPartOne = DateTime.now().millisecondsSinceEpoch;
      final postIdPartTwo = widget.userName.hashCode;
      final postId = '$postIdPartOne-$postIdPartTwo';

      final imageId = "${DateTime.now()}_${widget.userName}_$postId";

      String imageUrl = '';
      if (_imageFile != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('post_images')
            .child('$imageId.jpg');

        await storageRef.putFile(_imageFile!);
        imageUrl = await storageRef.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('posts').doc(postId).set({
        'title': _titleController.text,
        'content': _contentController.text,
        'post_image': imageUrl,
        'image_id': imageId,
        'post_id': postId,
        'author': widget.userName,
        'contains_image': _imageFile != null,
        'timestamp': FieldValue.serverTimestamp(),
        'song_url': song_url,
        'likes': [],
        'comments': [],
      });

      Navigator.of(context).pop();
    } catch (e) {
      print('Error uploading post: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title (optional)',
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                ),
                maxLines: null,
              ),
              const SizedBox(height: 16.0),
              if (_imageFile != null)
                Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: FileImage(_imageFile!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              _isUploading
                  ? const CircularProgressIndicator()
                  : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const ImageIcon(
                      AssetImage('assets/icons/camera.png'),
                      size: 35.0,
                    ),
                    onPressed: _pickImage,
                  ),
                  IconButton(
                    icon: const ImageIcon(
                      AssetImage('assets/icons/music.png'),
                      size: 35.0,
                    ), onPressed: _pickSong,
                  )
                ],
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _uploadPost,
                child: const Text('Post'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
