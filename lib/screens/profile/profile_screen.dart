import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../services/user_profile_service.dart';
import '../../services/profile_stats_service.dart';
import '../../models/user_profile.dart';
import '../../utils/date_format_utils.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileService = UserProfileService();
  final _statsService = ProfileStatsService();

  UserProfile? _profile;
  Map<String, int> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = context.read<UserProvider>().appUser;
    if (user == null) return;

    final profile = await _profileService.fetchProfile(user.uid);

    final stats = <String, int>{};
    switch (user.role) {
      case 'student':
        stats['Lost & Found Posts'] = await _statsService.lostFoundPostsBy(user.uid);
        break;
      case 'faculty':
        stats['Notices Posted'] = await _statsService.noticesPostedBy(user.uid);
        stats['Events Organized'] = await _statsService.eventsOrganizedBy(user.uid);
        break;
      case 'club_coordinator':
        stats['Events Organized'] = await _statsService.eventsOrganizedBy(user.uid);
        break;
      case 'super_admin':
        stats['Total Users'] = await _statsService.totalUsers();
        stats['Pending Approvals'] = await _statsService.pendingApprovalsCount();
        break;
    }

    if (mounted) {
      setState(() {
        _profile = profile;
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  String _roleSpecificLabel(String role) {
    switch (role) {
      case 'student':
        return 'Enrollment Number';
      case 'faculty':
        return 'Designation';
      case 'club_coordinator':
        return 'Position in Club';
      default:
        return '';
    }
  }

  String? _roleSpecificValue(String role, UserProfile? profile) {
    switch (role) {
      case 'student':
        return profile?.enrollmentNumber;
      case 'faculty':
        return profile?.designation;
      case 'club_coordinator':
        return profile?.clubPosition;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().appUser;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('User profile not found')),
      );
    }

    final roleLabel = _roleSpecificLabel(user.role);
    final roleValue = _roleSpecificValue(user.role, _profile);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: colorScheme.onSurface),
            tooltip: 'Edit Profile',
            onPressed: _isLoading
                ? null
                : () async {
                    final updated = await Navigator.push<UserProfile>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(
                          uid: user.uid,
                          role: user.role,
                          existingProfile: _profile ?? UserProfile.empty(user.uid),
                        ),
                      ),
                    );
                    if (updated != null && mounted) {
                      setState(() => _profile = updated);
                    }
                  },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: TextStyle(fontSize: 40, color: colorScheme.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            shape: BoxShape.circle,
                            border: Border.all(color: colorScheme.surface, width: 2),
                          ),
                          child: Icon(Icons.camera_alt, size: 16, color: colorScheme.onSecondaryContainer),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    user.name,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.role.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),

                // Role-based stats
                if (_stats.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _stats.entries.map((e) {
                        return Expanded(
                          child: Column(
                            children: [
                              Text(
                                '${e.value}',
                                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                e.key,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Core identity info
                _ProfileListTile(
                  icon: Icons.email_outlined,
                  title: 'Email Address',
                  subtitle: user.email,
                ),
                _ProfileListTile(
                  icon: Icons.business_outlined,
                  title: 'Department',
                  subtitle: user.department,
                ),
                if (user.club != null && user.club!.isNotEmpty)
                  _ProfileListTile(
                    icon: Icons.groups_outlined,
                    title: 'Club',
                    subtitle: user.club!,
                  ),
                if (_profile?.phone != null && _profile!.phone!.isNotEmpty)
                  _ProfileListTile(
                    icon: Icons.phone_outlined,
                    title: 'Phone',
                    subtitle: _profile!.phone!,
                  ),
                if (roleLabel.isNotEmpty && roleValue != null && roleValue.isNotEmpty)
                  _ProfileListTile(
                    icon: Icons.badge_outlined,
                    title: roleLabel,
                    subtitle: roleValue,
                  ),
                if (user.createdAt != null)
                  _ProfileListTile(
                    icon: Icons.calendar_today_outlined,
                    title: 'Member Since',
                    subtitle: DateFormatUtils.shortDate(user.createdAt!),
                  ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text('Log Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    onPressed: () async {
                      await AuthService().logout();
                      if (context.mounted) {
                        context.read<UserProvider>().clear();
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }
}

class _ProfileListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ProfileListTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
