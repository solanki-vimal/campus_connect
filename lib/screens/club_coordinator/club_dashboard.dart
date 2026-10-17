import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/dashboard_home_tab.dart';
import '../../widgets/notification_bell.dart';
import '../notices/notices_list_screen.dart';
import '../events/events_list_screen.dart';
import '../lost_found/lost_found_list_screen.dart';
import '../profile/profile_screen.dart';

class ClubDashboard extends StatefulWidget {
  const ClubDashboard({super.key});

  @override
  State<ClubDashboard> createState() => _ClubDashboardState();
}

class _ClubDashboardState extends State<ClubDashboard> {
  int _currentIndex = 0;

  static const List<String> _titles = ['Home', 'Events', 'Lost & Found'];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().appUser;

    final tabs = [
      DashboardHomeTab(
        onNavigateToNotices: () {
          // CC doesn't have a bottom nav tab for Notices, so push it directly
          Navigator.push(context, MaterialPageRoute(builder: (_) => const NoticesListScreen()));
        },
        onNavigateToEvents: () => setState(() => _currentIndex = 1),
      ),
      const EventsListScreen(),
      const LostFoundListScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            child: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                (user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : '?',
              ),
            ),
          ),
        ),
        title: Text(_currentIndex == 0 ? 'CampusConnect' : _titles[_currentIndex]),
        actions: [
          const NotificationBell(),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) context.read<UserProvider>().clear();
            },
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.event_outlined), selectedIcon: Icon(Icons.event), label: 'Events'),
          NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: 'Lost & Found'),
        ],
      ),
    );
  }
}
