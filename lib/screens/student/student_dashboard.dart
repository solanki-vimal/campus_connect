import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;

  static const List<String> _titles = [
    'Home',
    'Notices',
    'Events',
    'Lost & Found',
  ];

  // Placeholder tab bodies — these will be replaced with real screens
  // (NoticesListScreen, EventsListScreen, LostFoundListScreen) in Phase 2+.
  static const List<Widget> _tabs = [
    _HomeTabPlaceholder(),
    _ComingSoonTab(label: 'Notices'),
    _ComingSoonTab(label: 'Events'),
    _ComingSoonTab(label: 'Lost & Found'),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().appUser;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () {
              // TODO(Phase 6): navigate to Profile screen
            },
            child: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : '?',
              ),
            ),
          ),
        ),
        title: Text(_currentIndex == 0 ? 'Hi, ${user?.name.split(' ').first ?? ''}' : _titles[_currentIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO(Phase 5): navigate to Notifications screen
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) {
                context.read<UserProvider>().clear();
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign), label: 'Notices'),
          NavigationDestination(icon: Icon(Icons.event_outlined), selectedIcon: Icon(Icons.event), label: 'Events'),
          NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: 'Lost & Found'),
        ],
      ),
    );
  }
}

class _HomeTabPlaceholder extends StatelessWidget {
  const _HomeTabPlaceholder();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().appUser;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Welcome, ${user?.name ?? ''}',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text('Department: ${user?.department ?? ''}'),
            const SizedBox(height: 24),
            Text(
              'Recent Notices and Upcoming Events will appear here once the '
                  'Notice and Event modules are built (Phase 2/3).',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonTab extends StatelessWidget {
  final String label;
  const _ComingSoonTab({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$label module coming soon',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
      ),
    );
  }
}
