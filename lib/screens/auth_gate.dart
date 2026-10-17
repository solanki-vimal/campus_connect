import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'auth/login_screen.dart';
import 'pending_approval_screen.dart';
import 'student/student_dashboard.dart';
import 'faculty/faculty_dashboard.dart';
import 'club_coordinator/club_dashboard.dart';
import 'admin/admin_dashboard.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    'assets/logo.png',
                    width: 180,
                    height: 180,
                  ),
                  const SizedBox(height: 24),
                  // App Name
                  Text(
                    'CampusConnect',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Tagline / Subtitle
                  Text(
                    'Your Campus, Connected',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Loading Animation
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }

        final firebaseUser = snapshot.data;

        if (firebaseUser == null) {
          return const LoginScreen();
        }

        // Delegate to a StatefulWidget so loadUser() is only triggered once
        // per UID (in initState), never synchronously during build().
        return _RoleRouter(uid: firebaseUser.uid);
      },
    );
  }
}

class _RoleRouter extends StatefulWidget {
  final String uid;
  const _RoleRouter({required this.uid});

  @override
  State<_RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<_RoleRouter> {
  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void didUpdateWidget(covariant _RoleRouter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid) {
      _fetchProfile();
    }
  }

  void _fetchProfile() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<UserProvider>().loadUser(widget.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        if (userProvider.isLoading) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/logo.png', width: 140, height: 140),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Setting up your dashboard...',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (userProvider.errorMessage != null || userProvider.appUser == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('CampusConnect'),
              actions: [
                IconButton(
                  tooltip: 'Log Out',
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await AuthService().logout();
                    if (context.mounted) {
                      context.read<UserProvider>().clear();
                    }
                  },
                ),
              ],
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text(
                      userProvider.errorMessage ?? 'Unable to find user profile.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.read<UserProvider>().loadUser(widget.uid),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () async {
                        await AuthService().logout();
                        if (context.mounted) {
                          context.read<UserProvider>().clear();
                        }
                      },
                      child: const Text('Log out & return to Login'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final user = userProvider.appUser!;

        // Set up FCM topics and token for this user (safe to call repeatedly —
        // FCM topic subscriptions are idempotent).
        NotificationService.setupForUser(
          uid: user.uid,
          department: user.department,
        );

        switch (user.role) {
          case 'pending':
            return const PendingApprovalScreen();
          case 'faculty':
            return const FacultyDashboard();
          case 'club_coordinator':
            return const ClubDashboard();
          case 'super_admin':
            return const AdminDashboard();
          case 'student':
          default:
            return const StudentDashboard();
        }
      },
    );
  }
}