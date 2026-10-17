import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../services/user_service.dart';
import '../../widgets/confirm_delete_dialog.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UserService _userService = UserService();
  late final Stream<List<AppUser>> _pendingUsersStream;
  late final Stream<List<AppUser>> _allUsersStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pendingUsersStream = _userService.streamPendingUsers();
    _allUsersStream = _userService.streamAllUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildRoleBadge(String role) {
    Color bg;
    Color fg;

    switch (role.toLowerCase()) {
      case 'super_admin':
        bg = Colors.purple.shade50;
        fg = Colors.purple.shade800;
        break;
      case 'faculty':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
        break;
      case 'club_coordinator':
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade900;
        break;
      case 'pending':
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        break;
      default: // student
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        role.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  Future<void> _confirmDeleteUser(AppUser user) async {
    final confirm = await showDeleteConfirmDialog(
      context,
      itemLabel: 'user',
      itemName: '${user.name} (${user.email})',
    );

    if (confirm == true) {
      try {
        await _userService.deleteUser(user.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${user.name} removed')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete user: $e')),
          );
        }
      }
    }
  }

  Future<void> _approveUser(AppUser user) async {
    if (user.requestedRole == null) return;
    try {
      await _userService.approveUser(user.uid, user.requestedRole!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.name} approved as ${user.requestedRole}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve: $e')),
        );
      }
    }
  }

  Future<void> _rejectUser(AppUser user) async {
    final confirm = await showDeleteConfirmDialog(
      context,
      itemLabel: 'request',
      itemName: '${user.name} (${user.requestedRole ?? 'request'})',
    );
    if (confirm != true) return;

    try {
      await _userService.rejectUser(user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.name}\'s request rejected')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject: $e')),
        );
      }
    }
  }

  Future<void> _showChangeRoleDialog(AppUser user) async {
    const roles = ['student', 'faculty', 'club_coordinator', 'super_admin'];
    String selectedRole = user.role;

    final newRole = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Change Role: ${user.name}'),
              content: DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Select Role',
                  border: OutlineInputBorder(),
                ),
                items: roles.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.replaceAll('_', ' ').toUpperCase()),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedRole = val);
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, selectedRole),
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );

    if (newRole != null && newRole != user.role) {
      try {
        await _userService.updateUserRole(user.uid, newRole);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${user.name}\'s role updated to $newRole')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update role: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Pending Approvals'),
            Tab(text: 'All Users'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPendingTab(),
              _buildAllUsersTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPendingTab() {
    return StreamBuilder<List<AppUser>>(
      stream: _pendingUsersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return const Center(
            child: Text('No pending approvals', style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.email_outlined, size: 14, color: Colors.grey),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      user.email,
                                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildRoleBadge(user.requestedRole ?? 'user'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.business_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Dept: ${user.department}',
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                        if (user.club != null && user.club!.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.groups_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Club: ${user.club}',
                              style: const TextStyle(fontSize: 12, color: Colors.black87),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.close, size: 16, color: Colors.red),
                          label: const Text('Reject', style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () => _rejectUser(user),
                        ),
                        const SizedBox(width: 10),
                        FilledButton.icon(
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Approve'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () => _approveUser(user),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAllUsersTab() {
    return StreamBuilder<List<AppUser>>(
      stream: _allUsersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return const Center(
            child: Text('No users found', style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              elevation: 0.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  user.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildRoleBadge(user.role),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Dept: ${user.department}${user.club != null && user.club!.isNotEmpty ? ' · Club: ${user.club}' : ''}',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      onSelected: (action) {
                        if (action == 'role') {
                          _showChangeRoleDialog(user);
                        } else if (action == 'delete') {
                          _confirmDeleteUser(user);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'role',
                          child: Row(
                            children: [
                              Icon(Icons.manage_accounts_outlined, color: Colors.blue, size: 20),
                              SizedBox(width: 10),
                              Text('Change Role'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              SizedBox(width: 10),
                              Text('Delete User', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
