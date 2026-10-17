import 'package:flutter/material.dart';

/// Shared confirm-delete dialog, used by Notice and Event list screens.
/// Returns true if the user confirmed deletion, false/null otherwise.
Future<bool?> showDeleteConfirmDialog(
    BuildContext context, {
      required String itemLabel, // e.g. "notice" or "event"
      required String itemName, // e.g. the title/name of the specific item
    }) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Delete ${itemLabel[0].toUpperCase()}${itemLabel.substring(1)}'),
      content: Text('Are you sure you want to delete "$itemName"? This cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}
