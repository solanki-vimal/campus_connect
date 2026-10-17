import 'package:flutter/material.dart';
import '../../models/lost_item.dart';
import '../../utils/date_format_utils.dart';

class LostFoundDetailScreen extends StatelessWidget {
  final LostItem item;
  const LostFoundDetailScreen({required this.item, super.key});

  Color _typeColor(BuildContext context) => item.type == 'lost'
      ? Theme.of(context).colorScheme.error
      : Colors.green.shade700;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateStr = item.date != null
        ? DateFormatUtils.shortDate(item.date)
        : 'Not specified';
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar with image or gradient banner ──────────────
          SliverAppBar(
            expandedHeight: hasImage ? 260 : 160,
            pinned: true,
            backgroundColor: colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: hasImage
                  ? _NetworkImageBanner(imageUrl: item.imageUrl!)
                  : _GradientBanner(
                      type: item.type,
                      colorScheme: colorScheme,
                    ),
            ),
          ),

          // ── Body content ────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Type + Category chips
                Row(
                  children: [
                    _TypeChip(
                      label: item.type == 'lost' ? 'LOST' : 'FOUND',
                      color: _typeColor(context),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(item.category),
                      side: BorderSide.none,
                      backgroundColor:
                          colorScheme.secondaryContainer.withValues(alpha: 0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Title
                Text(
                  item.title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Info card
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color:
                            colorScheme.outline.withValues(alpha: 0.15)),
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                  ),
                  child: Column(
                    children: [
                      _infoRow(context, Icons.place_outlined, 'Location',
                          item.location),
                      Divider(
                          height: 1,
                          color: colorScheme.outline
                              .withValues(alpha: 0.12)),
                      _infoRow(context,
                          Icons.calendar_today_outlined, 'Date', dateStr),
                      Divider(
                          height: 1,
                          color: colorScheme.outline
                              .withValues(alpha: 0.12)),
                      _infoRow(context, Icons.person_outline,
                          'Reported by', item.postedByName),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Description
                Text('Description',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(item.description,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(height: 1.5)),
                const SizedBox(height: 28),

                // Contact card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.type == 'lost'
                            ? 'Did you find this item?'
                            : 'Is this your item?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Contact ${item.postedByName}:',
                        style: TextStyle(
                            color: colorScheme.onPrimaryContainer
                                .withValues(alpha: 0.8)),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.contact_page_outlined,
                              color: colorScheme.onPrimaryContainer,
                              size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.contactInfo,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
      BuildContext context, IconData icon, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant)),
              Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _NetworkImageBanner extends StatelessWidget {
  final String imageUrl;
  const _NetworkImageBanner({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullScreen(context),
      child: Hero(
        tag: imageUrl,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (_, _, _) => Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Icon(Icons.broken_image_outlined,
                size: 48, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  void _showFullScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: Hero(
              tag: imageUrl,
              child: InteractiveViewer(
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientBanner extends StatelessWidget {
  final String type;
  final ColorScheme colorScheme;
  const _GradientBanner({required this.type, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final color =
        type == 'lost' ? colorScheme.error : Colors.green.shade600;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.6)],
        ),
      ),
      child: Center(
        child: Icon(
          type == 'lost'
              ? Icons.search_off_outlined
              : Icons.inventory_2_outlined,
          size: 64,
          color: Colors.white.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final Color color;
  const _TypeChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontWeight: FontWeight.bold, color: color, fontSize: 12),
      ),
    );
  }
}
