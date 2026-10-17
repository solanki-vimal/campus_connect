import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/event.dart';
import '../../services/event_service.dart';
import '../../utils/date_format_utils.dart';
import 'event_registrants_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;

  const EventDetailScreen({required this.event, super.key});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _eventService = EventService();
  bool _isProcessing = false;

  Future<void> _toggleRegistration(bool currentlyRegistered) async {
    final user = context.read<UserProvider>().appUser;
    if (user == null) return;

    setState(() => _isProcessing = true);

    try {
      if (currentlyRegistered) {
        await _eventService.unregisterFromEvent(widget.event.id, user.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration cancelled')),
          );
        }
      } else {
        await _eventService.registerForEvent(
          eventId: widget.event.id,
          uid: user.uid,
          userName: user.name,
          userEmail: user.email,
          capacity: widget.event.capacity,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You\'re registered ✓')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().appUser;
    final isOrganizerOrAdmin =
        user?.uid == widget.event.organizerId || user?.role == 'super_admin';
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // ── Banner ────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            leading: const BackButton(),
            actions: [
              if (isOrganizerOrAdmin && widget.event.registrationRequired)
                IconButton(
                  icon: const Icon(Icons.people_outline),
                  tooltip: 'View Registrants',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            EventRegistrantsScreen(event: widget.event)),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Icon(
                        Icons.event,
                        size: 160,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TagChip(widget.event.category),
                            const SizedBox(height: 8),
                            Text(
                              widget.event.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _infoRow(Icons.calendar_today_outlined,
                            DateFormatUtils.shortDate(widget.event.date),
                            colorScheme),
                        const SizedBox(height: 12),
                        _infoRow(Icons.access_time_outlined,
                            '${widget.event.startTime} – ${widget.event.endTime}',
                            colorScheme),
                        const SizedBox(height: 12),
                        _infoRow(Icons.place_outlined, widget.event.venue,
                            colorScheme),
                        const SizedBox(height: 12),
                        _infoRow(
                          Icons.person_outline,
                          '${widget.event.organizerName} · ${widget.event.club ?? widget.event.department}',
                          colorScheme,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // About
                  Text('About',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(widget.event.description,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(height: 1.6)),

                  if (widget.event.registrationRequired) ...[
                    const SizedBox(height: 32),
                    _buildRegistrationSection(context, user?.uid),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationSection(BuildContext context, String? uid) {
    final colorScheme = Theme.of(context).colorScheme;
    return StreamBuilder<int>(
      stream: _eventService.streamRegistrationCount(widget.event.id),
      builder: (context, countSnapshot) {
        final count = countSnapshot.data ?? 0;
        final capacity = widget.event.capacity;
        final isFull = capacity != null && count >= capacity;

        return StreamBuilder<bool>(
          stream: uid == null
              ? const Stream<bool>.empty()
              : _eventService.streamIsRegistered(widget.event.id, uid),
          builder: (context, regSnapshot) {
            final isRegistered = regSnapshot.data ?? false;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.people_outline, size: 16,
                        color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      capacity != null
                          ? '$count / $capacity registered'
                          : '$count registered',
                      style:
                          TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: isRegistered
                      ? OutlinedButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () => _toggleRegistration(true),
                          icon: const Icon(Icons.check_circle,
                              color: Colors.green),
                          label: _isProcessing
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Text('Registered — Tap to Cancel'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                        )
                      : FilledButton.icon(
                          onPressed:
                              (isFull || _isProcessing) ? null : () => _toggleRegistration(false),
                          icon: const Icon(Icons.how_to_reg),
                          label: _isProcessing
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Text(isFull ? 'Event Full' : 'Register for Event'),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            textStyle: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String text, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
