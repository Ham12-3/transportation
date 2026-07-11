import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/stop_point.dart';
import '../models/transport_mode.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/chips.dart';
import '../widgets/common.dart';
import '../widgets/map_view.dart';
import '../widgets/rows.dart';
import '../widgets/state_views.dart';
import 'destination_search_sheet.dart';
import 'stop_arrivals_sheet.dart';

/// S1 — Home / Route Search.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // The mode chips shown in the Home grid (order matches the design).
  static const _modes = [
    TransportMode.saved,
    TransportMode.bus,
    TransportMode.cycle,
    TransportMode.tube,
    TransportMode.rail,
    TransportMode.tram,
    TransportMode.ferry,
    TransportMode.air,
    TransportMode.all,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchProvider);
    final location = ref.watch(currentLocationProvider);
    final nearby = ref.watch(nearbyStopsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFEAEDF1),
      body: Stack(
        children: [
          // ── MAP ──
          SizedBox(
            height: 360,
            width: double.infinity,
            child: location.when(
              data: (loc) => MapView(
                center: loc,
                zoom: 14.5,
                markers: [
                  userLocationMarker(loc),
                  ...nearby.maybeWhen(
                    data: (stops) => stops.take(8).map((s) => stopDot(s.position)),
                    orElse: () => const [],
                  ),
                ],
              ),
              loading: () => Container(color: AppColors.surfaceAlt),
              error: (_, _) => Container(color: AppColors.surfaceAlt),
            ),
          ),

          // ── DRAGGABLE PANEL ──
          DraggableScrollableSheet(
            initialChildSize: 0.62,
            minChildSize: 0.62,
            maxChildSize: 0.92,
            builder: (context, scroll) => Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.sheet,
                boxShadow: AppShadows.sheet,
              ),
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
                children: [
                  const Center(child: SheetGrabber()),
                  const SizedBox(height: 16),
                  _SearchCard(
                    fromLabel: query.fromLabel,
                    toLabel: query.toLabel,
                    hasDestination: query.isReady,
                    onSwap: () => ref.read(searchProvider.notifier).swap(),
                    onEditTo: () => _openDestinationSearch(context, ref),
                  ),
                  const SizedBox(height: 16),
                  _ModeGrid(
                    modes: _modes,
                    selected: query.modes,
                    onTap: (m) => ref.read(searchProvider.notifier).toggleMode(m),
                  ),
                  const SizedBox(height: 18),
                  const SectionLabel('Nearest Stops'),
                  _NearbyList(nearby: nearby),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openDestinationSearch(BuildContext context, WidgetRef ref) async {
    final stop = await showModalBottomSheet<StopPoint>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DestinationSearchSheet(),
    );
    if (stop != null) {
      // Use coordinates as the destination — TfL Journey Planner resolves these
      // directly and never returns an HTTP 300 disambiguation for them.
      final coord = '${stop.position.latitude},${stop.position.longitude}';
      ref.read(searchProvider.notifier).setTo(coord, label: stop.name);
      if (context.mounted) context.push('/results');
    }
  }
}

class _SearchCard extends StatelessWidget {
  const _SearchCard({
    required this.fromLabel,
    required this.toLabel,
    required this.hasDestination,
    required this.onSwap,
    required this.onEditTo,
  });
  final String fromLabel;
  final String toLabel;
  final bool hasDestination;
  final VoidCallback onSwap;
  final VoidCallback onEditTo;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.field,
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                _endpointRow(
                  dot: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.18), spreadRadius: 4)],
                    ),
                  ),
                  label: 'START',
                  value: fromLabel,
                  valueColor: AppColors.textStrong,
                ),
                const Divider(height: 1, color: AppColors.hairline),
                _endpointRow(
                  dot: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                        color: AppColors.red, borderRadius: BorderRadius.circular(2)),
                  ),
                  label: 'END',
                  value: toLabel,
                  valueColor: hasDestination ? AppColors.textStrong : const Color(0xFFB8C0C9),
                  onTap: onEditTo,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onSwap,
          child: Container(
            width: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.field,
              boxShadow: AppShadows.card,
            ),
            child: const Icon(Icons.swap_vert_rounded, color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _endpointRow({
    required Widget dot,
    required String label,
    required String value,
    required Color valueColor,
    VoidCallback? onTap,
  }) =>
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              dot,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
                    Text(value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700, color: valueColor)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _ModeGrid extends StatelessWidget {
  const _ModeGrid({required this.modes, required this.selected, required this.onTap});
  final List<TransportMode> modes;
  final Set<TransportMode> selected;
  final ValueChanged<TransportMode> onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.92,
      children: [
        for (final m in modes)
          ModeChip(
            mode: m,
            isAll: m == TransportMode.all,
            selected: selected.contains(m),
            onTap: () => onTap(m),
          ),
      ],
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.06);
  }
}

class _NearbyList extends ConsumerWidget {
  const _NearbyList({required this.nearby});
  final AsyncValue<List<StopPoint>> nearby;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return nearby.when(
      loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 40), child: LoadingView()),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: ErrorView(
          message: 'Could not load nearby stops.',
          onRetry: () => ref.invalidate(nearbyStopsProvider),
        ),
      ),
      data: (stops) {
        if (stops.isEmpty) {
          return const MessageView(
              icon: Icons.location_searching_rounded,
              title: 'No stops nearby',
              message: 'Move the map or widen your mode filter.');
        }
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.field,
            boxShadow: AppShadows.card,
          ),
          child: Column(
            children: [
              for (var i = 0; i < stops.length && i < 6; i++) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.hairline),
                StopRow(
                  stop: stops[i],
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => StopArrivalsSheet(stop: stops[i]),
                  ),
                ),
              ],
            ],
          ),
        ).animate().fadeIn(duration: 350.ms);
      },
    );
  }
}
