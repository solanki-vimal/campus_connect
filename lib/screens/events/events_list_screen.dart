import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/event_service.dart';
import '../../models/event.dart';
import '../../widgets/event_card.dart';
import '../../widgets/confirm_delete_dialog.dart';
import 'create_event_screen.dart';
import 'event_detail_screen.dart';

class EventsListScreen extends StatefulWidget {
  const EventsListScreen({super.key});

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  final _eventService = EventService();
  String _filter = 'upcoming'; // 'upcoming' | 'mine'

  bool _canCreate(String? role) =>
      role == 'faculty' || role == 'club_coordinator' || role == 'super_admin';

  bool _canSeeMyEvents(String? role) =>
      role == 'faculty' || role == 'club_coordinator' || role == 'super_admin';

  /// Owner can manage their own event; Super Admin can manage any event.
  bool _canManage(Event event, String? uid, String? role) {
    if (role == 'super_admin') return true;
    if (event.organizerId == uid) return true;
    return false;
  }

  Future<void> _confirmDelete(BuildContext context, Event event) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      itemLabel: 'event',
      itemName: event.name,
    );

    if (confirmed == true) {
      try {
        await _eventService.deleteEvent(event.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event deleted')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().appUser;
    final canCreate = _canCreate(user?.role);
    final showMyEventsTab = _canSeeMyEvents(user?.role);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Upcoming'),
                  selected: _filter == 'upcoming',
                  showCheckmark: false,
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _filter == 'upcoming' ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  side: BorderSide.none,
                  onSelected: (_) => setState(() => _filter = 'upcoming'),
                ),
                if (showMyEventsTab) ...[
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('My Events'),
                    selected: _filter == 'mine',
                    showCheckmark: false,
                    selectedColor: Theme.of(context).colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _filter == 'mine' ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide.none,
                    onSelected: (_) => setState(() => _filter = 'mine'),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Event>>(
              stream: _filter == 'upcoming'
                  ? _eventService.streamEvents()
                  : _eventService.streamMyEvents(user?.uid ?? ''),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Failed to load events: ${snapshot.error}'),
                    ),
                  );
                }

                final events = snapshot.data ?? [];

                if (events.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.event_outlined, size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            _filter == 'upcoming'
                                ? 'No upcoming events yet'
                                : "You haven't created any events yet",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 80),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final canManage = _canManage(event, user?.uid, user?.role);

                    return EventCard(
                      event: event,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
                        );
                      },
                      onEdit: canManage
                          ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateEventScreen(existingEvent: event),
                          ),
                        );
                      }
                          : null,
                      onDelete: canManage ? () => _confirmDelete(context, event) : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateEventScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Create'),
      )
          : null,
    );
  }
}
