import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';

class FacultyDashboard extends StatelessWidget {
  const FacultyDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().appUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty Dashboard'),
        actions: [
          IconButton(
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
        child: Text('Welcome, ${user?.name ?? ''}\nDepartment: ${user?.department ?? ''}'),
      ),
    );
  }
}
