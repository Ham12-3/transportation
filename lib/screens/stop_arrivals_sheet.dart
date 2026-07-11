import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/saved_item.dart';
import '../models/stop_point.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/common.dart';
import '../widgets/rows.dart';
import '../widgets/state_views.dart';

/// Live arrivals for a tapped stop, auto-refreshing every 30s.
class StopArrivalsSheet extends ConsumerWidget {
  const StopArrivalsSheet({super.key, required this.stop});
  final StopPoint stop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arrivals = ref.watch(arrivalsProvider(stop.id));
    final saved = ref.watch(savedProvider.notifier);
    final isSaved = ref.watch(savedProvider).any((s) => s.id == stop.id);

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.sheet),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          const SheetGrabber(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
            child: Row(
              children: [
                const IconBadge(Icons.directions_transit_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stop.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      Text('${stop.walkMinutes} min walk · Live',
                          style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(isSaved ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: AppColors.primary),
                  onPressed: () => saved.toggle(SavedItem(
                    id: stop.id,
                    kind: SavedKind.stop,
                    title: stop.name,
                    subtitle: '${stop.walkMinutes} min walk',
                    lat: stop.position.latitude,
                    lon: stop.position.longitude,
                    savedAt: DateTime.now(),
                  )),
                ),
              ],
            ),
          ),
          Flexible(
            child: arrivals.when(
              loading: () => const Padding(padding: EdgeInsets.all(30), child: LoadingView()),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(20),
                child: ErrorView(onRetry: () => ref.invalidate(arrivalsProvider(stop.id))),
              ),
              data: (list) => list.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: MessageView(
                          icon: Icons.schedule_rounded,
                          title: 'No live arrivals',
                          message: 'Nothing due at this stop right now.'),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.hairline),
                      itemBuilder: (_, i) => Container(
                        color: Colors.white,
                        child: ArrivalRow(arrival: list[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
