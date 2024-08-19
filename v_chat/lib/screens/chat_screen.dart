import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../models/message.dart' as chat_message;
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import 'chat_info_screen.dart';

class ChatScreen extends StatefulWidget {
  static const routeName = '/chat';
  final String username;
  final String currentUserId;
  final String chatId;
  final String recipientDocId;
  final String recipientName;

  const ChatScreen(
      {super.key, required this.username, required this.currentUserId, required this.chatId, required this.recipientDocId, required this.recipientName});

  @override
  _ChatScreenState createState() => _ChatScreenState();

}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final storage = FirebaseStorage.instance;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _animation;
  String bgUrl = '';

  String? repliedMessageId;
  String? selectedEffect;
  String? selectedSongUrl;

  @override
  void initState() {
    super.initState();
    _fetchBackgroundImage();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);

    _scrollController.addListener(() {
      if (_scrollController.offset > _scrollController.position.minScrollExtent) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.minScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _sendMessage(String text, String effect, String selectedSongUrl) {
    try {
      final message = chat_message.Message(
          id: widget.username,
          senderId: widget.currentUserId,
          text: text,
          messageId: widget.username +
              DateTime.now().millisecondsSinceEpoch.toString() +
              widget.currentUserId,
          timestamp: DateTime.now(),
          messageUserName: widget.username,
          repliedMessage: repliedMessageId ?? '',
          edited: false,
          reactions: {},
          effect: effect,
          read: false,
          recipientUserName: widget.recipientName,
          selectedSongUrl: selectedSongUrl,
      );


      FirebaseFirestore.instance.collection(widget.currentUserId).doc(widget.chatId).update({
        'lastMessage': text,
        'timestamp': Timestamp.fromMillisecondsSinceEpoch(
          message.timestamp.millisecondsSinceEpoch,
        ),
        'recipientDocId': widget.recipientDocId,
      });

      FirebaseFirestore.instance
          .collection(widget.recipientDocId)
          .doc(widget.chatId)
          .update({
        'lastMessage': text,
        'timestamp': Timestamp.fromMillisecondsSinceEpoch(
          message.timestamp.millisecondsSinceEpoch,
        ),
        'read': false,
        'recipientDocId': widget.currentUserId,
      });

      FirebaseFirestore.instance
          .collection(widget.chatId)
          .doc(message.messageId)
          .set(message.toMap());

      repliedMessageId = null;
      selectedEffect = null;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fell off trying to send your message.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _selectEffect() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Wrap(
            children: [
              _buildEffectCategory(
                title: 'Color',
                effects: [
                  'rainbow',
                  'fire',
                  'highlight',
                ],
                icon: Icons.color_lens,
              ),
              _buildEffectCategory(
                title: 'Formatting',
                effects: [
                  'bold',
                  'italic',
                  'underline',
                  'strike',
                ],
                icon: Icons.text_fields,
              ),
              _buildEffectCategory(
                title: 'Visual',
                effects: [
                  'glow',
                  'shadow',
                  'mirror',
                  'blur',
                  'scale',
                  'shift',
                ],
                icon: Icons.visibility,
              ),
              _buildEffectCategory(
                title: 'Special',
                effects: [
                  'hidden',
                  'jump',
                  'rotate',
                  'flip',
                  'grow'
                ],
                icon: Icons.star_outline,
              ),
              const Center(
                child: Text(
                  "Created by Esvin Joshua",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildEffectCategory({
    required String title,
    required List<String> effects,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            children: [
              Icon(icon, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 3,
          ),
          itemCount: effects.length,
          itemBuilder: (context, index) {
            final effect = effects[index];
            return GestureDetector(
              onTap: () {
                selectedEffect = effect;
                Navigator.of(context).pop();
              },
              child: Card(
                color: Colors.grey[200],
                child: Center(
                  child: Text(
                    effect,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _selectGif() async {
    final searchController = TextEditingController();
    final gifs = <String>[];

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search for GIFs...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (query) async {
                    if (query.isNotEmpty) {
                      final response = await http.get(
                        Uri.parse(
                          'https://api.giphy.com/v1/gifs/search?api_key=Bxn3vKFVF0cljCQRfAO2gatrUkUoiZkn&q=$query&limit=20',
                        ),
                      );
                      final data = jsonDecode(response.body);
                      final fetchedGifs = (data['data'] as List)
                          .map((gif) => gif['images']['downsized_medium']['url'] as String)
                          .toList();
                      setState(() {
                        gifs.clear();
                        gifs.addAll(fetchedGifs);
                      });
                    } else {
                      final response = await http.get(
                        Uri.parse(
                          'https://api.giphy.com/v1/gifs/search?api_key=Bxn3vKFVF0cljCQRfAO2gatrUkUoiZkn&q=top&limit=20',
                        ),
                      );
                      final data = jsonDecode(response.body);
                      final fetchedGifs = (data['data'] as List)
                          .map((gif) => gif['images']['downsized_medium']['url'] as String)
                          .toList();
                      setState(() {
                        gifs.clear();
                        gifs.addAll(fetchedGifs);
                      });
                    }
                  },
                ),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                    ),
                    itemCount: gifs.length,
                    itemBuilder: (context, index) {
                      final gifUrl = gifs[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          _sendMessage(gifUrl, '', '');
                        },
                        child: Image.network(gifUrl),
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
  }

  void _reactToMessage(String messageId) {
    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("'react'"),
          content: Wrap(
            children: [
              for (final emoji in ['😀', '😂', '❤️', '😦', '😡', '👍', '👎'])
                GestureDetector(
                  onTap: () {
                    FirebaseFirestore.instance
                        .collection(widget.chatId)
                        .doc(messageId)
                        .update({
                      'reactions.$emoji': FieldValue.increment(1),
                    });

                    FirebaseFirestore.instance
                        .collection(widget.currentUserId)
                        .doc(widget.chatId)
                        .update({
                      'lastMessage': emoji,
                      'timestamp': Timestamp.fromMillisecondsSinceEpoch(
                        DateTime.now().millisecondsSinceEpoch,
                      ),
                      'recipientDocId': widget.recipientDocId,
                    });

                    FirebaseFirestore.instance
                        .collection(widget.recipientDocId)
                        .doc(widget.chatId)
                        .update({
                      'lastMessage': emoji,
                      'timestamp': Timestamp.fromMillisecondsSinceEpoch(
                        DateTime.now().millisecondsSinceEpoch,
                      ),
                      'recipientDocId': widget.currentUserId,
                    });

                    Navigator.of(ctx).pop();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _editMessage(String messageId, String messageText) {
    Navigator.of(context).pop();

    showDialog(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        controller.text = messageText;
        return AlertDialog(
          title: const Text('Second Chance'),
          content: TextField(
            controller: controller,
          ),
          actions: [
            TextButton(
              child: const Text('Nevermind'),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
            TextButton(
              child: const Text('DONE'),
              onPressed: () {
                final newText = controller.text;
                if (newText.isNotEmpty) {
                  FirebaseFirestore.instance
                      .collection(widget.chatId)
                      .doc(messageId)
                      .update({
                    'text': newText,
                    'edited': true,
                  });
                  Navigator.of(ctx).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection(widget.chatId).doc(messageId).get();
      final data = doc.data() as Map<String, dynamic>;
      final text = data['text'] as String;

      if (text.startsWith('https://firebasestorage.googleapis.com')) {
        final start = text.indexOf('/o/') + 3;
        final end = text.indexOf('?alt');
        final filename = text.substring(start, end);
        final filenameDecoded = filename.replaceAll('%2F', '/').replaceAll('%3A', ':').replaceAll('%20', ' ');
        final ref = FirebaseStorage.instance.ref().child(filenameDecoded);

        await ref.delete();

        await FirebaseFirestore.instance.collection(widget.chatId).doc(messageId).delete();

        final messages = await FirebaseFirestore.instance.collection(widget.chatId).orderBy('timestamp', descending: true).get();

        if (messages.docs.isNotEmpty) {
          final lastMessage = messages.docs.first;

          await FirebaseFirestore.instance.collection(widget.currentUserId).doc(widget.chatId).update({
            'lastMessage': lastMessage['text'],
            'timestamp': lastMessage['timestamp'],
            'recipientDocId': widget.recipientDocId,
          });

          await FirebaseFirestore.instance.collection(widget.recipientDocId).doc(widget.chatId).update({
            'lastMessage': lastMessage['text'],
            'timestamp': lastMessage['timestamp'],
            'recipientDocId': widget.currentUserId,
          });
        }
      }
      else {
        FirebaseFirestore.instance.collection(widget.chatId).doc(messageId).delete();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fell off trying to delete message.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchBackgroundImage() async {
    try {
      final url = await (
      FirebaseStorage.instance.ref().child('media/${widget.chatId}/background.jpg').getDownloadURL()
      );
      setState(() {
        bgUrl = url;
      });

    } catch (e) {
      print('Error fetching background image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton:
      Padding( 
        padding: const EdgeInsets.only(bottom: 100.0),
        child: ScaleTransition(
          scale: _animation,
          child: FloatingActionButton(
            elevation: 10,
            onPressed: _scrollToBottom,
            child: Image.asset(
              'assets/icons/down.png',
              width: 30,
              height: 30,
            ),
          ),
        ),
      ),
      appBar: AppBar(
        title: TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ChatInfoScreen(
                  chatId: widget.chatId,
                  recipientUserName: widget.recipientName,
                  mediaPath: 'media/${widget.chatId}',
                ),
              ),
            );
          },
          child: Text(
            widget.recipientName,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Image.asset(
                'assets/icons/refresh.png',
                width: 30,
                height: 30,
            ),
            onPressed: () {
              setState(() {
                selectedEffect = null;
                repliedMessageId = null;
              });
            },
          ),
        ],
      ),

      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: Image.network(bgUrl).image,
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection(widget.chatId)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: ColorTween(
                          begin: Colors.blue,
                          end: Colors.red,
                        ).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: Curves.easeInOut,
                          ),
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return const Center(
                        child: Text('Failed to fetch messages.')
                    );
                  }

                  final messages = snapshot.data!.docs
                      .map((doc) => chat_message.Message.fromSnapshot(doc))
                      .toList();

                  FirebaseFirestore.instance.collection(widget.chatId).get().then((snapshot) {
                    for (DocumentSnapshot doc in snapshot.docs) {
                        try {
                          if (doc['senderId'] != widget.currentUserId) {
                            doc.reference.update({'read': true});
                          }
                        } catch (e) {
                          print('Error updating read status: $e');
                        }
                    }
                  });

                  FirebaseFirestore.instance.collection(widget.currentUserId).doc(widget.chatId).update({'read': true});

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return GestureDetector(
                        onPanStart: (_) {
                          setState(() {
                            repliedMessageId = message.text.startsWith('https') ? 'media' : message.text;
                          });
                        },
                        child: MessageBubble(
                          key: ValueKey(message.messageId),
                          messageId: message.messageId,
                          message: message,
                          isMe: message.senderId == widget.currentUserId,
                          onReact: _reactToMessage,
                          onEdit: _editMessage,
                          onDelete: _deleteMessage,
                          currentUserId: widget.currentUserId,
                          senderId: message.senderId,
                          edited: message.edited,
                          reactions: message.reactions,
                          messageUserName: widget.username,
                          effect: message.effect,
                          timestamp: message.timestamp,
                          selectedSongUrl: message.selectedSongUrl,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            MessageInput(
              onGifSelect: _selectGif,
                repliedMessage: repliedMessageId,
                onSendMessage: (text) {
                  _sendMessage(text, selectedEffect ?? '', selectedSongUrl ?? '');
                },
                onSelectSong: (songUrl) {
                  selectedSongUrl = songUrl;
                  _sendMessage('', '', songUrl);
                  selectedSongUrl = null;
                },
                onSelectEffect: _selectEffect,
                onMediaSelect: (media) async {
                  try {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sending media...'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                    final ref = storage.ref().child('media/${widget.chatId}/${DateTime.now()}_${widget.currentUserId}.png');
                    await ref.putFile(media);
                    final url = await ref.getDownloadURL();
                    _sendMessage(url, '', '');
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to send media.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}