import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/spotify_service.dart';

class MessageInput extends StatefulWidget {
  final void Function(String) onSendMessage;
  final VoidCallback onSelectEffect;
  final Function(File) onMediaSelect;
  final VoidCallback onGifSelect;
  String? repliedMessage;
  Function(dynamic songUrl) onSelectSong;


  MessageInput({
    super.key,
    required this.onSendMessage,
    required this.onSelectEffect,
    required this.onGifSelect,
    required this.onMediaSelect,
    this.repliedMessage,
    required this.onSelectSong,
  });

  @override
  _MessageInputState createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  String _message = '';
  File? _selectedImage;
  late final AnimationController _animationController;
  String song_url = '';

  final List<String> _hintTexts = [
    'message...', 'Type something...', '*Suspenseful music plays*', 'What\'s on your mind?', 'Say something...',
    'What\'s up?', 'What\'s the plan?', 'What\'s the news?', 'What\'s the word?', 'What\'s the story?',
    'What\'s the deal?', 'What\'s the buzz?', 'What\'s the latest?', 'What\'s the gossip?', 'What\'s the scoop?',
    'What\'s the lowdown?', 'What\'s the drill?', 'What\'s the dealio?', 'What\'s the haps?', 'What\'s the happs?',
    'What\'s the hap?', 'What\'s the hapz'
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _sendMessage() {
    if (_message.trim().isEmpty) return;
    widget.onSendMessage(_message);
    _controller.clear();
    setState(() {
      song_url = '';
      _message = '';
      _selectedImage = null;
    });
  }

  void _sendImage() {
    if (_selectedImage == null) return;
    widget.onMediaSelect(_selectedImage!);
    setState(() {
      _selectedImage = null;
    });
  }

  void _showEasterEgg() {
    if (_animationController.isAnimating) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Scaffold(
            backgroundColor: Colors.black.withOpacity(0.8),
            body: Stack(
              children: [
                AnimatedBackground(animation: _animationController),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Thx for using this app :)',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 10.0,
                              color: Colors.pinkAccent,
                              offset: Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          _sendMessage();
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                        child: const Text('nice'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
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
                            _controller.clear();
                            _message = '🎵 ${song['name']} by ${song['singer']}';
                            song_url = 'https://open.spotify.com/embed/track/${song['uri'].split(':').last}';
                            widget.onSelectSong(song_url);
                            song_url = '';
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      height: _selectedImage == null ? null : 270,
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.repliedMessage != null)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                  child: Text(
                    widget.repliedMessage!.length > 20
                        ? '${widget.repliedMessage!.substring(0, 20)}...'
                        : widget.repliedMessage!,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel),
                  onPressed: () {
                    setState(() {
                      widget.repliedMessage = null;
                    });
                  },
                ),
              ],
            ),
          if (_selectedImage != null)
            ClipRect(
              child: Stack(
                children: [
                  Image.file(
                    _selectedImage!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _selectedImage = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

          Row(
            children: [
              GestureDetector(
                onTap: _selectedImage == null ? widget.onSelectEffect : null,
                child: const Image(
                  image: AssetImage('assets/icons/effect_icon.png'),
                  width: 30,
                  height: 30,
                )
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: _hintTexts[Random().nextInt(_hintTexts.length)],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _message = value;
                    });
                  },
                  onSubmitted: (value) {
                    if (_selectedImage != null) {
                      _sendImage();
                    } else {
                      _sendMessage();
                    }
                  },
                ),
              ),

              if (_message.isNotEmpty || _selectedImage != null)
                GestureDetector(
                  child: const Image(
                    image: AssetImage('assets/icons/send_icon.png'),
                    width: 30,
                    height: 30,
                  ),
                  onTap: () {
                      _message.trim().isEmpty && _selectedImage == null ? null : () {
                        widget.repliedMessage = null;
                        if (_selectedImage != null) {
                          _sendImage();
                        } else {
                          _sendMessage();
                        }
                      }();
                  },
                ),
              if (_message.isEmpty && _selectedImage == null)
                GestureDetector(
                  child: const Image(
                    image: AssetImage('assets/icons/attach_icon.png'),
                    width: 35,
                    height: 35,
                  ),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return Wrap(
                          children: [
                            ListTile(
                              leading: const ImageIcon(
                                AssetImage('assets/icons/gif.png'),
                                size: 35,
                                color: Colors.black,
                              ),
                              title: const Text('Select a GIF'),
                              onTap: () {
                                Navigator.pop(context);
                                widget.onGifSelect();
                              },
                            ),
                            ListTile(
                              leading: const ImageIcon(
                                AssetImage('assets/icons/music.png'),
                                size: 35,
                                color: Colors.black,
                              ),
                              title: const Text('Send a song'),
                              onTap: _pickSong,
                            ),
                            ListTile(
                              leading: const ImageIcon(
                                AssetImage('assets/icons/gallery.png'),
                                size: 35,
                                color: Colors.black,
                              ),
                              title: const Text('Gallery'),
                              onTap: () {
                                Navigator.pop(context);
                                _pickImage(ImageSource.gallery);
                              },
                            ),
                            ListTile(
                              leading: const ImageIcon(
                                AssetImage('assets/icons/camera.png'),
                                size: 35,
                                color: Colors.black,
                              ),
                              title: const Text('Camera'),
                              onTap: () {
                                Navigator.pop(context);
                                _pickImage(ImageSource.camera);
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              if (_message.toLowerCase() == 'the best music')
                IconButton(
                  icon: const Icon(Icons.badge_outlined),
                  onPressed: _showEasterEgg,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class AnimatedBackground extends StatelessWidget {
  final Animation<double> animation;

  const AnimatedBackground({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return CustomPaint(
          painter: HeartBackgroundPainter(animation.value),
          child: child,
        );
      },
    );
  }
}

class HeartBackgroundPainter extends CustomPainter {
  final double animationValue;

  HeartBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.pinkAccent.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final heartPath = Path()
      ..moveTo(0, 0)
      ..addOval(const Rect.fromLTWH(-10, -10, 20, 20))
      ..addOval(const Rect.fromLTWH(-10, 0, 20, 20))
      ..lineTo(0, 30)
      ..close();

    final random = Random();

    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final heartOffset = Offset(x, y);

      canvas.save();
      canvas.translate(heartOffset.dx, heartOffset.dy);
      canvas.rotate(animationValue * 2 * pi);
      canvas.drawPath(
        heartPath,
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
