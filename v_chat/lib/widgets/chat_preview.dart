import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../screens/chat_screen.dart';

class ChatPreview extends StatelessWidget {
  final String chatId;
  final String recieverName;
  final String currentName;
  final String lastMessage;
  final String userId;
  final Timestamp timestamp;
  final String recipientDocId;
  final bool readStatus;

  const ChatPreview({
    super.key,
    required this.chatId,
    required this.recieverName,
    required this.currentName,
    required this.lastMessage,
    required this.userId,
    required this.timestamp,
    required this.recipientDocId,
    required this.readStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      color: readStatus ? Colors.white : Colors.grey[200],
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Text(
          recieverName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        subtitle: Text(
          lastMessage.startsWith('https') ? 'Sent a link - ${TimeOfDay
              .fromDateTime(timestamp.toDate()).format(context)}' :
          '${lastMessage.length > 20
              ? '${lastMessage.substring(0, 20)}...'
              : lastMessage} - ${TimeOfDay.fromDateTime(timestamp.toDate())
              .format(context)}',
          style: TextStyle(
            color: readStatus ? Colors.grey[700] : Colors.teal,
            fontWeight: readStatus ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert, color: Colors.teal),
          itemBuilder: (context) =>
          [
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete Chat'),
            ),
            const PopupMenuItem(
              value: 'mute',
              child: Text('Mute Chat'),
            ),
          ],
          onSelected: (value) {
            if (value == 'delete') {
              _deleteChat(context);
            } else {
              FirebaseMessaging.instance.unsubscribeFromTopic(chatId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chat muted. Click on the chat to un-mute.'),
                  backgroundColor: Colors.teal,
                  duration: Duration(seconds: 1),
                ),
              );
            }
          },
        ),
        leading: !readStatus
            ? const Icon(Icons.circle, color: Colors.teal)
            : null,
        onTap: () {
          FirebaseMessaging.instance.subscribeToTopic(chatId);

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  ChatScreen(
                    username: currentName,
                    currentUserId: userId,
                    chatId: chatId,
                    recipientDocId: recipientDocId,
                    recipientName: recieverName,
                  ),
            ),
          );
        },
      ),
    );
  }

  void _deleteChat(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Chat'),
          content: const Text('Deleting a chat will remove it from your record only. Are you sure you want to delete this chat?'),
          actions: [
            TextButton(
              child: const Text('Nevermind'),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance.collection(userId).doc(chatId).delete();
                  await FirebaseFirestore.instance.collection(chatId).get().then((snapshot) {
                    for (DocumentSnapshot doc in snapshot.docs) {
                      doc.reference.delete();
                    }
                  });
                  Navigator.of(ctx).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fell off while deleting chat.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
