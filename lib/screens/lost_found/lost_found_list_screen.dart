import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/lost_found_service.dart';
import '../../models/lost_item.dart';
import '../../utils/date_format_utils.dart';
import '../../widgets/confirm_delete_dialog.dart';
import 'create_lost_found_screen.dart';
import 'lost_found_detail_screen.dart';

class LostFoundListScreen extends StatefulWidget {
  const LostFoundListScreen({super.key});

  @override
  State<LostFoundListScreen> createState() => _LostFoundListScreenState();
}

class _LostFoundListScreenState extends State<LostFoundListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _service = LostFoundService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _canManage(LostItem item, String? uid, String? role) {
    if (role == 'super_admin') return true;
    return item.postedBy == uid;
  }

  Future<void> _confirmDelete(BuildContext context, LostItem item) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      itemLabel: 'report',
      itemName: item.title,
    );
    if (confirmed == true) {
      try {
        await _service.deleteItem(item.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report deleted')),
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

  Future<void> _markResolved(BuildContext context, LostItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Resolved?'),
        content: Text(
          item.type == 'lost'
              ? 'Mark "${item.title}" as found/returned? It will be removed from the list.'
              : 'Mark "${item.title}" as claimed? It will be removed from the list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Resolved'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.markResolved(item.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marked as resolved ✓')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().appUser;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                labelColor: Theme.of(context).colorScheme.onPrimaryContainer,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Lost'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Found'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ItemList(
                  stream: _service.streamLostItems(),
                  emptyMessage: 'No lost items reported',
                  emptyIcon: Icons.search_off_outlined,
                  user: user,
                  canManage: _canManage,
                  onDelete: _confirmDelete,
                  onMarkResolved: _markResolved,
                ),
                _ItemList(
                  stream: _service.streamFoundItems(),
                  emptyMessage: 'No found items reported',
                  emptyIcon: Icons.inventory_2_outlined,
                  user: user,
                  canManage: _canManage,
                  onDelete: _confirmDelete,
                  onMarkResolved: _markResolved,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateLostFoundScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Report'),
      ),
    );
  }
}

class _ItemList extends StatelessWidget {
  final Stream<List<LostItem>> stream;
  final String emptyMessage;
  final IconData emptyIcon;
  final dynamic user;
  final bool Function(LostItem, String?, String?) canManage;
  final Future<void> Function(BuildContext, LostItem) onDelete;
  final Future<void> Function(BuildContext, LostItem) onMarkResolved;

  const _ItemList({
    required this.stream,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.user,
    required this.canManage,
    required this.onDelete,
    required this.onMarkResolved,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LostItem>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(emptyIcon, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text(emptyMessage,
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                const Text('Tap "Report" to post one.',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            final item = items[index];
            final manage = canManage(item, user?.uid, user?.role);
            return _LostItemCard(
              item: item,
              canManage: manage,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LostFoundDetailScreen(item: item),
                ),
              ),
              onDelete: manage ? () => onDelete(context, item) : null,
              onMarkResolved:
                  manage ? () => onMarkResolved(context, item) : null,
            );
          },
        );
      },
    );
  }
}

class _LostItemCard extends StatelessWidget {
  final LostItem item;
  final bool canManage;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onMarkResolved;

  const _LostItemCard({
    required this.item,
    required this.canManage,
    required this.onTap,
    this.onDelete,
    this.onMarkResolved,
  });

  Color _typeColor(BuildContext context) => item.type == 'lost'
      ? Theme.of(context).colorScheme.error
      : Colors.green.shade700;

  Widget _typeBadge(BuildContext context) => Container(
        width: 56,
        height: 56,
        color: _typeColor(context).withValues(alpha: 0.12),
        child: Icon(
          item.type == 'lost'
              ? Icons.search_off_outlined
              : Icons.inventory_2_outlined,
          color: _typeColor(context),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormatUtils.shortDate(item.date);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail: image if available, otherwise type-icon badge
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? Image.network(
                        item.imageUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _typeBadge(context),
                      )
                    : _typeBadge(context),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _typeColor(context).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.type.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _typeColor(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.category,
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined,
                            size: 13, color: Colors.grey),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            item.location,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (dateStr.isNotEmpty)
                          Text(dateStr,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Posted by ${item.postedByName}',
                      style:
                          const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // Actions menu
              if (canManage)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (value) {
                    if (value == 'resolve') onMarkResolved?.call();
                    if (value == 'delete') onDelete?.call();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'resolve',
                      child: ListTile(
                        leading: Icon(Icons.check_circle_outline),
                        title: Text('Mark Resolved'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading:
                            Icon(Icons.delete_outline, color: Colors.red),
                        title: Text('Delete',
                            style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
