import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/saved_item.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/common.dart';
import '../widgets/state_views.dart';

/// Saved routes & stops, persisted locally with Hive.
class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(savedProvider);
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(20, top + 16, 20, 16),
            alignment: Alignment.centerLeft,
            child: Text('Saved', style: Theme.of(context).textTheme.displaySmall),
          ),
          Expanded(
            child: items.isEmpty
                ? const MessageView(
                    brandMark: true,
                    title: 'Nothing saved yet',
                    message: 'Star a route or stop to keep it here for quick access.')
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _SavedTile(
                      item: items[i],
                      onRemove: () => ref.read(savedProvider.notifier).remove(items[i].id),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SavedTile extends StatelessWidget {
  const _SavedTile({required this.item, required this.onRemove});
  final SavedItem item;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) {
    final isRoute = item.kind == SavedKind.route;
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(color: AppColors.red, borderRadius: AppRadius.card),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: AppCard(
        child: Row(
          children: [
            IconBadge(isRoute ? Icons.route_rounded : Icons.place_rounded, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textStrong)),
                  Text(item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.star_rounded, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}
