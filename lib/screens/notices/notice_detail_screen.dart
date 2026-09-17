import 'package:flutter/material.dart';
import '../../models/notice.dart';

class NoticeDetailScreen extends StatelessWidget {
  final Notice notice;

  const NoticeDetailScreen({required this.notice, super.key});

  Color _priorityColor() {
    switch (notice.priority) {
      case 'urgent':
        return Colors.red;
      case 'important':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String _priorityLabel() {
    switch (notice.priority) {
      case 'urgent':
        return 'Urgent';
      case 'important':
        return 'Important';
      default:
        return 'Normal';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Chip(
              label: Text(_priorityLabel()),
              backgroundColor: _priorityColor().withValues(alpha: 0.15),
              labelStyle: TextStyle(color: _priorityColor(), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              notice.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                Chip(label: Text(notice.category)),
                Chip(label: Text(notice.department == 'all' ? 'General' : notice.department)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Posted by ${notice.postedByName} on ${_formatDate(notice.datePosted)}',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const Divider(height: 32),
            Text(
              notice.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (notice.expiryDate != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_busy, size: 18),
                    const SizedBox(width: 8),
                    Text('Expires on ${_formatDate(notice.expiryDate)}'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
