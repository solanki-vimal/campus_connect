import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../models/event_registration.dart';
import '../../services/event_service.dart';
import '../../utils/date_format_utils.dart';

class EventRegistrantsScreen extends StatelessWidget {
  final Event event;

  const EventRegistrantsScreen({required this.event, super.key});

  @override
  Widget build(BuildContext context) {
    final eventService = EventService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrants'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                event.name,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<EventRegistration>>(
        stream: eventService.streamRegistrants(event.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final registrants = snapshot.data ?? [];

          if (registrants.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No one has registered yet', style: TextStyle(color: Colors.grey)),
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${registrants.length}'
                    '${event.capacity != null ? ' / ${event.capacity}' : ''} registered',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: registrants.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final r = registrants[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(r.userName.isNotEmpty ? r.userName[0].toUpperCase() : '?'),
                      ),
                      title: Text(r.userName),
                      subtitle: Text(r.userEmail),
                      trailing: Text(
                        DateFormatUtils.shortDate(r.registeredAt),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
