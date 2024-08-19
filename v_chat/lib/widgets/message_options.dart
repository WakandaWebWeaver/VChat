import 'package:flutter/material.dart';

class MessageOptions extends StatelessWidget {
  final VoidCallback onReact;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MessageOptions({
    super.key,
    required this.onReact,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        ListTile(
          leading: const Icon(Icons.emoji_emotions),
          title: const Text('React'),
          onTap: onReact,
        ),
        if (onEdit != null)
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit'),
            onTap: onEdit,
          ),
        if (onDelete != null)
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete'),
            onTap: onDelete,
          ),
      ],
    );
  }
}
