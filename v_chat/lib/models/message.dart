import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  String id;
  String senderId;
  String text;
  String messageId;
  DateTime timestamp;
  String messageUserName;
  String recipientUserName;
  String repliedMessage;
  bool edited;
  String selectedSongUrl;
  Map<String, int> reactions;
  String effect;
  bool read;

  Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.messageId,
    required this.timestamp,
    required this.messageUserName,
    required this.recipientUserName,
    required this.repliedMessage,
    required this.edited,
    this.selectedSongUrl = '',
    this.reactions = const {},
    this.effect = '',
    this.read = false,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      messageId: map['messageId'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      messageUserName: map['messageUserName'] ?? '',
      recipientUserName: map['recipientUserName'] ?? '',
      repliedMessage: map['repliedMessage'] ?? '',
      edited: map['edited'] ?? false,
      selectedSongUrl: map['selectedSongUrl'] ?? '',
      reactions: Map<String, int>.from(map['reactions'] ?? {}),
      effect: map['effect'] ?? '',
      read: map['read'] ?? false,
    );
  }

  factory Message.fromSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    return Message(
      id: data['id'] ?? '',
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      messageId: data['messageId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      messageUserName: data['messageUserName'] ?? '',
      recipientUserName: data['recipientUserName'] ?? '',
      repliedMessage: data['repliedMessage'] ?? '',
      edited: data['edited'] ?? false,
      selectedSongUrl: data['selectedSongUrl'] ?? '',
      reactions: Map<String, int>.from(data['reactions'] ?? {}),
      effect: data['effect'] ?? '',
      read: data['read'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'text': text,
      'messageId': messageId,
      'timestamp': timestamp,
      'messageUserName': messageUserName,
      'recipientUserName': recipientUserName,
      'repliedMessage': repliedMessage,
      'edited': edited,
      'reactions': reactions,
      'selectedSongUrl': selectedSongUrl,
      'effect': effect,
      'read': read,
    };
  }
}
