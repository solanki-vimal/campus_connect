import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/in_app_notification_service.dart';
import '../../models/app_notification.dart';
import '../notices/notice_detail_screen.dart';
import '../events/event_detail_screen.dart';
import '../../services/notice_service.dart';
import '../../services/event_service.dart';
import '../../utils/date_format_utils.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = InAppNotificationService();

  @override
  void initState() {
    super.initState();
    // Mark all as read when the screen opens
    final uid = context.read<UserProvider>().appUser?.uid;
    if (uid != null) {
      _service.markAllRead(uid);
    }
  }

  Future<void> _onTap(BuildContext context, AppNotification notif) async {
    if (notif.type == 'notice') {
      try {
        final notices = await NoticeService().streamAllNotices().first;
        final notice = notices.firstWhere((n) => n.id == notif.refId);
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NoticeDetailScreen(notice: notice)),
          );
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notice no longer available')),
          );
        }
      }
    } else if (notif.type == 'event') {
      try {
        final events = await EventService().streamEvents().first;
        final event = events.firstWhere((e) => e.id == notif.refId);
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
          );
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event no longer available')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<UserProvider>().appUser?.uid ?? '';
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Notifications',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: _service.streamNotifications(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none_outlined,
                      size: 64,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Notices and events will appear here',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              indent: 72,
              color: colorScheme.outline.withValues(alpha: 0.1),
            ),
            itemBuilder: (context, index) {
              final notif = items[index];
              return _NotificationTile(
                notif: notif,
                onTap: () => _onTap(context, notif),
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notif;
  final VoidCallback onTap;

  const _NotificationTile({required this.notif, required this.onTap});

  IconData get _icon =>
      notif.type == 'event' ? Icons.event_outlined : Icons.campaign_outlined;

  Color _iconColor(ColorScheme cs) =>
      notif.type == 'event' ? Colors.blue : cs.primary;

  String _timeAgo() => DateFormatUtils.timeAgo(notif.createdAt);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUnread = !notif.read;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isUnread
            ? colorScheme.primaryContainer.withValues(alpha: 0.12)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _iconColor(colorScheme).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon,
                  size: 22, color: _iconColor(colorScheme)),
            ),
            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            fontWeight: isUnread
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8, top: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.body,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(),
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 16),
          ],
        ),
      ),
    );
  }
}
