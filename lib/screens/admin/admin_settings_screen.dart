import 'package:flutter/material.dart';
import 'manage_metadata_screen.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: const CircleAvatar(child: Icon(Icons.business)),
          title: const Text('Manage Departments'),
          subtitle: const Text('Dynamic list of departments for signup'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ManageMetadataScreen(
                  title: 'Departments',
                  collectionPath: 'departments',
                  itemLabel: 'Department',
                  icon: Icons.business,
                ),
              ),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const CircleAvatar(child: Icon(Icons.category)),
          title: const Text('Manage Event Categories'),
          subtitle: const Text('Dynamic list of categories for events'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ManageMetadataScreen(
                  title: 'Event Categories',
                  collectionPath: 'event_categories',
                  itemLabel: 'Category',
                  icon: Icons.category,
                ),
              ),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const CircleAvatar(child: Icon(Icons.announcement_outlined)),
          title: const Text('Manage Notice Categories'),
          subtitle: const Text('Dynamic list of categories for notices'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ManageMetadataScreen(
                  title: 'Notice Categories',
                  collectionPath: 'notice_categories',
                  itemLabel: 'Category',
                  icon: Icons.announcement_outlined,
                ),
              ),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const CircleAvatar(child: Icon(Icons.groups)),
          title: const Text('Manage Clubs'),
          subtitle: const Text('Dynamic list of clubs for signup'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ManageMetadataScreen(
                  title: 'Clubs',
                  collectionPath: 'clubs',
                  itemLabel: 'Club',
                  icon: Icons.groups,
                ),
              ),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const CircleAvatar(child: Icon(Icons.search)),
          title: const Text('Manage Lost & Found Categories'),
          subtitle: const Text('Dynamic list of item categories'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ManageMetadataScreen(
                  title: 'Lost & Found Categories',
                  collectionPath: 'lost_found_categories',
                  itemLabel: 'Category',
                  icon: Icons.search,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
