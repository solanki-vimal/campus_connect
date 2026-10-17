import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/notice_service.dart';
import '../../models/notice.dart';
import '../../widgets/notice_card.dart';
import '../../widgets/confirm_delete_dialog.dart';
import 'create_notice_screen.dart';
import 'notice_detail_screen.dart';

class NoticesListScreen extends StatefulWidget {
  const NoticesListScreen({super.key});

  @override
  State<NoticesListScreen> createState() => _NoticesListScreenState();
}

class _NoticesListScreenState extends State<NoticesListScreen> {
  final _noticeService = NoticeService();
  String _filter = 'general'; // 'general' | 'department'

  bool _canCreate(String? role) => role == 'faculty' || role == 'super_admin';

  /// Faculty can edit/delete only their own notices. Super Admin can
  /// edit/delete any notice (moderation).
  bool _canManage(Notice notice, String? uid, String? role) {
    if (role == 'super_admin') return true;
    if (role == 'faculty' && notice.postedBy == uid) return true;
    return false;
  }

  Future<void> _confirmDelete(BuildContext context, Notice notice) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      itemLabel: 'notice',
      itemName: notice.title,
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
                  label: const Text('College-wide'),
                  selected: _filter == 'general',
                  showCheckmark: false,
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _filter == 'general' ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  side: BorderSide.none,
                  onSelected: (_) => setState(() => _filter = 'general'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('My Department'),
                  selected: _filter == 'department',
                  showCheckmark: false,
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _filter == 'department' ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  side: BorderSide.none,
                  onSelected: (_) => setState(() => _filter = 'department'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Notice>>(
              stream: _filter == 'general'
                  ? _noticeService.streamGeneralNotices()
                  : _noticeService.streamDepartmentOnly(user?.department ?? ''),
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
                            _filter == 'general'
                                ? 'No college-wide notices yet'
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
