import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/message.dart';
import '../screens/image_preview_screen.dart';
import 'message_options.dart';
import 'package:url_launcher/url_launcher.dart';

class MessageBubble extends StatefulWidget {
  final String messageId;
  final Message message;
  final bool isMe;
  final Function(String) onReact;
  final Function(String, String) onEdit;
  final Function(String) onDelete;
  final String currentUserId;
  final String senderId;
  final bool edited;
  final Map<String, int> reactions;
  final String messageUserName;
  final String effect;
  final String selectedSongUrl;
  final DateTime timestamp;

  const MessageBubble({
    super.key,
    required this.messageId,
    required this.message,
    required this.isMe,
    required this.onReact,
    required this.onEdit,
    required this.onDelete,
    required this.currentUserId,
    required this.senderId,
    required this.selectedSongUrl,
    required this.edited,
    required this.reactions,
    required this.messageUserName,
    required this.effect,
    required this.timestamp,
  });

  @override
  _MessageBubbleState createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _jumpAnimation;
  bool _isTextVisible = false;
  bool _isJumping = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _jumpAnimation = Tween<double>(begin: 0, end: -20).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(targetUrl) async {
    final Uri url = Uri.parse(targetUrl);
    print(
        'Launching URL: $url'
    );

    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    } else {
      await launchUrl(
        url,
      );
    }
  }

  void _toggleTextVisibility() {
    if (widget.effect == 'hidden') {
      setState(() {
        _isTextVisible = !_isTextVisible;
      });
    } else if (widget.effect == 'jump') {
      if (!_isJumping) {
        setState(() {
          _isJumping = true;
        });
        _animationController.forward().then((_) {
          _animationController.reverse().then((_) {
            setState(() {
              _isJumping = false;
            });
          });
        });
      } else if (widget.effect == 'spin'){
        if (_animationController.isCompleted) {
          _animationController.reverse();
        } else {
          _animationController.forward();
        }
      }
    }
  }

  void _viewImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImagePreviewScreen(imageUrl: imageUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget messageText = Text(
      widget.message.text,
      style: const TextStyle(
        fontSize: 18,
        color: Colors.black, // Updated color
      ),
    );

    if (widget.effect == 'jump') {
      messageText = SlideTransition(
        position: _jumpAnimation.drive(Tween<Offset>(begin: Offset.zero, end: const Offset(0, 0.05))),
        child: messageText,
      );
    } else if (widget.effect == 'bold') {
      messageText = Text(
        widget.message.text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black, // Updated color
        ),
      );
    } else if (widget.effect == 'italic') {
      messageText = Text(
        widget.message.text,
        style: const TextStyle(
          fontSize: 16,
          fontStyle: FontStyle.italic,
          color: Colors.black, // Updated color
        ),
      );
    } else if (widget.effect == 'underline') {
      messageText = Text(
        widget.message.text,
        style: const TextStyle(
          fontSize: 16,
          decoration: TextDecoration.underline,
          color: Colors.black, // Updated color
        ),
      );
    } else if (widget.effect == 'strikethrough') {
      messageText = Text(
        widget.message.text,
        style: const TextStyle(
          fontSize: 16,
          decoration: TextDecoration.lineThrough,
          color: Colors.black, // Updated color
        ),
      );
    } else if (widget.effect == 'highlight') {
      messageText = Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.yellow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          widget.message.text,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black, // Updated color
          ),
        ),
      );
    } else if (widget.effect == 'rainbow') {
      messageText = ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [
            Colors.red,
            Colors.orange,
            Colors.yellow,
            Colors.green,
            Colors.blue,
            Colors.indigo,
            Colors.purple,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: Text(
          widget.message.text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white, // Color will be overridden by shader
          ),
        ),
      );
    } else if (widget.effect == 'fire') {
      messageText = ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [
            Colors.red,
            Colors.orange,
            Colors.yellow,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: Text(
          widget.message.text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white, // Color will be overridden by shader
          ),
        ),
      );
    } else if (widget.effect == 'glow') {
      messageText = Text(
        widget.message.text,
        style: const TextStyle(
          fontSize: 16,
          shadows: [
            Shadow(
              blurRadius: 10.0,
              color: Colors.blue,
              offset: Offset(5.0, 5.0),
            ),
          ],
        ),
      );
    } else if (widget.effect == 'shadow') {
      messageText = Text(
        widget.message.text,
        style: const TextStyle(
          fontSize: 16,
          shadows: [
            Shadow(
              blurRadius: 10.0,
              color: Colors.black,
              offset: Offset(5.0, 5.0),
            ),
          ],
        ),
      );
    } else if (widget.effect == 'blur') {
      messageText = Text(
        widget.message.text,
        style: TextStyle(
          fontSize: 16,
          foreground: Paint()
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        ),
      );
    } else if (widget.effect == 'mirror') {
      messageText = Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(3.14),
        child: messageText,
      );
    } else if (widget.effect == 'flip') {
      messageText = Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationX(3.14),
        child: messageText,
      );
    } else if (widget.effect == 'strike') {
      messageText = Text(
        widget.message.text,
        style: const TextStyle(
          fontSize: 16,
          decoration: TextDecoration.lineThrough,
          color: Colors.black, // Updated color
        ),
      );
    } else if (widget.effect == 'rotate') {
      messageText = Transform.rotate(
        angle: 3.15 / 4,
        child: messageText,
      );
    } else if (widget.effect == 'scale') {
      messageText = Transform.scale(
        scale: 1.5,
        child: messageText,
      );
    } else if (widget.effect == 'translate') {
      messageText = Transform.translate(
        offset: const Offset(20, 20),
        child: messageText,
      );
    } else if (widget.effect == 'grow') {
      messageText = AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        width: _isTextVisible ? MediaQuery.of(context).size.width * 0.6 : 0,
        child: messageText,
      );
    }

    return Column(
      crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onLongPress: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => MessageOptions(
                onReact: () {
                  widget.onReact(widget.messageId);
                },
                onEdit: widget.message.senderId == widget.currentUserId ? () {
                  widget.onEdit(widget.messageId, widget.message.text);
                } : null,
                onDelete: widget.message.senderId == widget.currentUserId ? () {
                  widget.onDelete(widget.messageId);
                  Navigator.of(context).pop();
                } : null,
              ),
            );
          },
          onTap: _toggleTextVisibility,
          child: Container(
            width: MediaQuery.of(context).size.width * 2 / 3,
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isMe ? Colors.blue[100] : Colors.green[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.effect.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.star_outline_sharp,
                      color: Colors.black,
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.message.repliedMessage.isNotEmpty)
                        if (widget.message.repliedMessage.startsWith('http'))
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: GestureDetector(
                              onTap: () => _viewImage(widget.message.repliedMessage),
                              child: Image.network(
                                widget.message.repliedMessage,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: widget.isMe ? Colors.green[300] : Colors.blue[100],
                            ),
                            child: Text(
                              'Replying to: ${widget.message.repliedMessage.length > 20
                                  ? '${widget.message.repliedMessage.substring(0, 20)}...'
                                  : widget.message.repliedMessage}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                              ),
                            ),
                          ),
                      const SizedBox(height: 4),
                      if (widget.message.text.startsWith('http'))
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: GestureDetector(
                            onTap: () => _viewImage(widget.message.text),
                            child: Image.network(
                              widget.message.text,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return RichText(
                                  text: TextSpan(
                                    text: widget.message.text,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.blue,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        _launchURL(widget.message.text);
                                      },
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                      if (widget.selectedSongUrl.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8.0),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              height: 80,
                              width: double.infinity,
                              child: WebViewWidget(
                                  controller: WebViewController()
                                    ..setJavaScriptMode(JavaScriptMode.unrestricted)
                                    ..loadRequest(Uri.parse(
                                      widget.selectedSongUrl,
                                    ))
                              ),
                            ),
                          ],
                        ),
                      if (!widget.effect.contains('hidden') && !widget.message.text.startsWith('http'))
                        messageText,
                      if (widget.effect == 'hidden' && !widget.message.text.startsWith('http'))
                        _isTextVisible
                            ? Text(
                          widget.message.text,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        )
                            : const Text(
                          'Tap to reveal',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        TimeOfDay.fromDateTime(widget.timestamp).format(context),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),

                      if (widget.isMe)
                        Text(
                          widget.message.read ? 'Read' : 'Delivered',
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.black,
                          ),
                        ),

                      const SizedBox(height: 4),
                      if (widget.edited)
                        const Text(
                          'Edited',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.black,
                          ),
                        ),
                      const SizedBox(height: 4),
                      // Display reactions
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: widget.reactions.entries.map((entry) {
                          final emoji = entry.key;
                          final count = entry.value;
                          return Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(emoji),
                                const SizedBox(width: 4),
                                Text(count.toString()),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
