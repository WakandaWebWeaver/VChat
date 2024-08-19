import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../services/spotify_service.dart';
import 'image_preview_screen.dart';

class ProfileSettingsScreen extends StatefulWidget {
  final String userId;

  const ProfileSettingsScreen({
    super.key,
    required this.userId,
  });

  @override
  _ProfileSettingsScreenState createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _songController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  String song_url = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _displayNameController.text = user.displayName ?? '';
        FirebaseFirestore.instance.collection('users').doc(user.displayName).get().then((doc) {
          _bioController.text = doc['bio'] ?? '';
          // _usernameController.text = doc['username'] ?? '';
        });
      });
    }
  }

  Future<bool> _usernameExists(String username) async {
    final snapshot = await FirebaseFirestore.instance.collection('users').where('username', isEqualTo: username).get();
    return snapshot.docs.isNotEmpty;
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
                            _songController.text = '🎵 ${song['name']} by ${song['singer']}';
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

  Future<void> _updateProfile() async {
    final displayName = _displayNameController.text;
    final username = _usernameController.text;
    final bio = _bioController.text;
    final song = _songController.text;

    if (displayName.isNotEmpty || username.isNotEmpty || bio.isNotEmpty || song.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = _auth.currentUser;
        if (user != null) {
          if (displayName.isNotEmpty) {
            await user.updateDisplayName(displayName);
          }

          if (username.isNotEmpty) {
            final usernameExists = await _usernameExists(username);
            if (usernameExists) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Username already exists.')),
              );
              return;
            }

            await FirebaseFirestore.instance.collection('users').doc(user.displayName).update({
              'username': username,
            });
          }

          if (bio.isNotEmpty) {
            await FirebaseFirestore.instance.collection('users').doc(user.displayName).update({
              'bio': bio,
            });
          }

          if (song_url.isNotEmpty) {
            await FirebaseFirestore.instance.collection('users').doc(user.displayName).update({
              'profile_song': song_url,
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile.')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final CroppedFile? croppedImage = await ImageCropper().cropImage(
          sourcePath: image.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Cropper',
              toolbarColor: Colors.teal,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
            )
          ]
      );

      if (croppedImage != null) {
        await _uploadProfilePicture(croppedImage.path);
      }
    }
  }

  Future<void> _uploadProfilePicture(String filePath) async {
    try {
      final userId = widget.userId;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_media')
          .child(userId)
          .child('profile_picture.jpg');

      final uploadTask = storageRef.putFile(File(filePath));
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      final user = _auth.currentUser;

      if (user != null) {
        await user.updatePhotoURL(downloadUrl);
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'profilePictureUrl': downloadUrl,
        });

        setState(() {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ProfileSettingsScreen(
                userId: userId,
              ),
            ),
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile picture.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VChat - Profile Settings'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickProfilePicture,
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: NetworkImage(
                    _auth.currentUser?.photoURL ??
                        'https://www.pngitem.com/pimgs/m/146-1468479_my-profile-icon-blank-profile-picture-circle-hd.png',
                  ),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      color: Colors.teal,
                      padding: const EdgeInsets.all(8.0),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                onLongPress: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ImagePreviewScreen(
                        imageUrl: _auth.currentUser!.photoURL as String,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _displayNameController,
              decoration: const InputDecoration(labelText: 'Display Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(labelText: 'Bio'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _pickSong,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Pick Song',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Update Profile',
                style: TextStyle(color: Colors.white),
              ),
            ),
            // const SizedBox(height: 20),
            // const Row(
            //   children: [
            //     Expanded(
            //       child: Divider(),
            //     ),
            //     Padding(
            //       padding: EdgeInsets.symmetric(horizontal: 8.0),
            //       child: Text(
            //         'Danger Zone',
            //         style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold),
            //       ),
            //     ),
            //     Expanded(
            //       child: Divider(),
            //     ),
            //   ],
            // ),
            // const SizedBox(height: 20),
            // ElevatedButton(
            //   onPressed: () {
            //     showDialog(
            //       context: context,
            //       builder: (context) {
            //         return AlertDialog(
            //           title: const Text('Delete Account'),
            //           content: const Text('Are you sure you want to delete your account?'),
            //           actions: [
            //             TextButton(
            //               onPressed: () {
            //                 Navigator.of(context).pop();
            //               },
            //               child: const Text('Cancel'),
            //             ),
            //             TextButton(
            //               onPressed: () async {
            //                 final user = _auth.currentUser;
            //                 if (user != null) {
            //                   showDialog(
            //                     context: context,
            //                     builder: (context) {
            //                       return AlertDialog(
            //                         title: const Text('Enter Password'),
            //                         content: TextField(
            //                           decoration: const InputDecoration(labelText: 'Password'),
            //                           obscureText: true,
            //                           controller: _oldPasswordController,
            //                         ),
            //                         actions: [
            //                           TextButton(
            //                             onPressed: () {
            //                               Navigator.of(context).pop();
            //                             },
            //                             child: const Text('Cancel'),
            //                           ),
            //                           TextButton(
            //                             onPressed: () async {
            //                               try {
            //                                 await user.reauthenticateWithCredential(
            //                                   EmailAuthProvider.credential(
            //                                     email: user.email!,
            //                                     password: _oldPasswordController.text,
            //                                   ),
            //                                 );
            //                                 await user.delete();
            //                                 Navigator.of(context).pop();
            //                                 Navigator.of(context).pushReplacementNamed('/');
            //                               } catch (e) {
            //                                 ScaffoldMessenger.of(context).showSnackBar(
            //                                   const SnackBar(
            //                                     content: Text('Failed to delete account.'),
            //                                     backgroundColor: Colors.red,
            //                                   ),
            //                                 );
            //                               }
            //                             },
            //                             child: const Text('Delete'),
            //                           ),
            //                         ],
            //                       );
            //                     },
            //                   );
            //                 }
            //               },
            //               child: const Text(
            //                 'Delete',
            //                 style: TextStyle(color: Colors.red),
            //               ),
            //             ),
            //           ],
            //         );
            //       },
            //     );
            //   },
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: Colors.red,
            //     padding: const EdgeInsets.symmetric(vertical: 14),
            //   ),
            //   child: const Text(
            //     'Delete Account',
            //     style: TextStyle(color: Colors.white),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
