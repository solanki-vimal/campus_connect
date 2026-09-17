import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/notice_service.dart';
import '../../models/notice.dart';
import '../../widgets/notice_card.dart';
import 'create_notice_screen.dart';
import 'notice_detail_screen.dart';

class NoticesListScreen extends StatefulWidget {
  const NoticesListScreen({super.key});

  @override
  State<NoticesListScreen> createState() => _NoticesListScreenState();
}

class _NoticesListScreenState extends State<NoticesListScreen> {
  final _noticeService = NoticeService();
  String _filter = 'all'; // 'all' | 'department'

  bool _canCreate(String? role) => role == 'faculty' || role == 'super_admin';

  /// Faculty can edit/delete only their own notices. Super Admin can
  /// edit/delete any notice (moderation).
  bool _canManage(Notice notice, String? uid, String? role) {
    if (role == 'super_admin') return true;
    if (role == 'faculty' && notice.postedBy == uid) return true;
    return false;
  }

  Future<void> _confirmDelete(BuildContext context, Notice notice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Notice'),
        content: Text('Are you sure you want to delete "${notice.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _noticeService.deleteNotice(notice.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notice deleted')),
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

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _filter == 'all',
                  onSelected: (_) => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('My Department'),
                  selected: _filter == 'department',
                  onSelected: (_) => setState(() => _filter = 'department'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Notice>>(
              stream: _filter == 'all'
                  ? _noticeService.streamAllNotices()
                  : _noticeService.streamNoticesForDepartment(user?.department ?? ''),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Failed to load notices: ${snapshot.error}'),
                    ),
                  );
                }

                final notices = snapshot.data ?? [];

                if (notices.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.campaign_outlined, size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            _filter == 'all'
                                ? 'No notices yet'
                                : 'No notices for your department yet',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 80),
                  itemCount: notices.length,
                  itemBuilder: (context, index) {
                    final notice = notices[index];
                    final canManage = _canManage(notice, user?.uid, user?.role);

                    return NoticeCard(
                      notice: notice,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => NoticeDetailScreen(notice: notice)),
                        );
                      },
                      onEdit: canManage
                          ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateNoticeScreen(existingNotice: notice),
                          ),
                        );
                      }
                          : null,
                      onDelete: canManage ? () => _confirmDelete(context, notice) : null,
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
            MaterialPageRoute(builder: (_) => const CreateNoticeScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Create'),
      )
          : null,
    );
  }
}
