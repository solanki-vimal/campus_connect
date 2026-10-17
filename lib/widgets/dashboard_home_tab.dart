import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/notice_service.dart';
import '../services/event_service.dart';
import '../models/notice.dart';
import '../models/event.dart';
import '../screens/notices/notice_detail_screen.dart';
import '../screens/events/event_detail_screen.dart';
import '../screens/notices/create_notice_screen.dart';
import '../screens/events/create_event_screen.dart';

/// Shared home/dashboard tab used by Student, Faculty, and Club Coordinator
/// dashboards. Shows a greeting, urgent notices, and upcoming events.
///
/// [onNavigateToNotices] and [onNavigateToEvents] are callbacks so the parent
/// dashboard can switch its [NavigationBar] to the right index.
class DashboardHomeTab extends StatelessWidget {
  final VoidCallback onNavigateToNotices;
  final VoidCallback onNavigateToEvents;

  const DashboardHomeTab({
    required this.onNavigateToNotices,
    required this.onNavigateToEvents,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().appUser;
    final noticeService = NoticeService();
    final eventService = EventService();

    final canPost = user?.role == 'faculty' || user?.role == 'super_admin';
    final canCreateEvent = user?.role == 'faculty' ||
        user?.role == 'club_coordinator' ||
        user?.role == 'super_admin';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Greeting card ────────────────────────────────────────────
          _GreetingCard(user: user),
          const SizedBox(height: 28),

          // ── Quick Actions — only for roles that can CREATE content ──
          // (Students skip this entirely; bottom nav already covers navigation)
          if (canPost || canCreateEvent) ...[
            _SectionHeader(title: 'Quick Actions', onSeeAll: null),
            const SizedBox(height: 12),
            Row(
              children: [
                if (canPost)
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.campaign,
                      title: 'Post Notice',
                      subtitle: 'Publish updates',
                      color: Colors.purple,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CreateNoticeScreen()),
                      ),
                    ),
                  ),
                if (canPost && canCreateEvent) const SizedBox(width: 12),
                if (canCreateEvent)
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.event,
                      title: 'Create Event',
                      subtitle: 'Schedule event',
                      color: Colors.blue,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CreateEventScreen()),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),
          ],



          // ── Recent Notices ────────────────────────────────────────────
          _SectionHeader(
            title: 'Recent Notices',
            onSeeAll: onNavigateToNotices,
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<Notice>>(
            stream: noticeService.streamStudentFeed(user?.department ?? ''),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _SectionSkeleton();
              }
              final notices = (snapshot.data ?? []).take(3).toList();
              if (notices.isEmpty) {
                return const _EmptySection(
                  icon: Icons.campaign_outlined,
                  message: 'No notices yet',
                );
              }
              return Column(
                children: notices
                    .map((n) => _NoticeRow(
                          notice: n,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    NoticeDetailScreen(notice: n)),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 28),

          // ── Upcoming Events ───────────────────────────────────────────
          _SectionHeader(
            title: 'Upcoming Events',
            onSeeAll: onNavigateToEvents,
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<Event>>(
            stream: eventService.streamEvents(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _SectionSkeleton();
              }
              final now = DateTime.now();
              final events = (snapshot.data ?? [])
                  .where((e) => e.date != null && e.date!.isAfter(now))
                  .take(3)
                  .toList();
              if (events.isEmpty) {
                return const _EmptySection(
                  icon: Icons.event_outlined,
                  message: 'No upcoming events',
                );
              }
              return Column(
                children: events
                    .map((e) => _EventRow(
                          event: e,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    EventDetailScreen(event: e)),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _GreetingCard extends StatelessWidget {
  final dynamic user;
  const _GreetingCard({required this.user});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
            Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Optional: Add a faint icon graphic on the right
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.school,
              size: 100,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user?.name ?? '',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${user?.department ?? ''}'
                  '${user?.club != null && user!.club!.isNotEmpty ? ' · ${user!.club}' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: Text(
              'See all',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary),
            ),
          ),
      ],
    );
  }
}



class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeRow extends StatelessWidget {
  final Notice notice;
  final VoidCallback onTap;
  const _NoticeRow({required this.notice, required this.onTap});

  Color _priorityColor(BuildContext context) {
    switch (notice.priority) {
      case 'urgent':
        return Theme.of(context).colorScheme.error;
      case 'important':
        return Colors.orange;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: _priorityColor(context),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(
          notice.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          notice.category,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, size: 18),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  const _EventRow({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateStr = event.date != null
        ? '${event.date!.day}/${event.date!.month}/${event.date!.year}'
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.event_outlined,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
        title: Text(
          event.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '$dateStr · ${event.venue}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, size: 18),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptySection({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: Colors.grey),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _SectionSkeleton extends StatelessWidget {
  const _SectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (_) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                )),
            title: Container(
                height: 14,
                width: 120,
                color: Colors.grey.shade200),
            subtitle: Container(
                height: 11,
                width: 80,
                color: Colors.grey.shade100),
          ),
        ),
      ),
    );
  }
}
