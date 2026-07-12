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
import '../widgets/roundel.dart';
import '../widgets/rows.dart';
import '../widgets/state_views.dart';
import 'destination_search_sheet.dart';
import 'stop_arrivals_sheet.dart';

/// S1 — Home / Route Search.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // The travel modes a journey can be planned by (Air lives on its own tab;
  // "Saved" and "All" were never modes and have been removed from this grid).
  static const _modes = [
    TransportMode.tube,
    TransportMode.bus,
    TransportMode.rail,
    TransportMode.tram,
    TransportMode.ferry,
    TransportMode.cycle,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchProvider);
    final location = ref.watch(currentLocationProvider);
    final nearby = ref.watch(nearbyStopsProvider);
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      body: Stack(
        children: [
          // ── MAP ──
          SizedBox(
            height: 380,
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
              loading: () => const _MapPlaceholder(label: 'Finding you…'),
              error: (_, _) => const _MapPlaceholder(label: 'Map unavailable'),
            ),
          ),

          // Brand lockup floating over the map
          Positioned(
            top: top + 12,
            left: 16,
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 16, 8),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: AppRadius.pill,
                boxShadow: AppShadows.float,
              ),
              child: const RoundelWordmark(text: 'Underground', size: 22),
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.4, curve: Curves.easeOut),

          // ── DRAGGABLE PANEL ──
          DraggableScrollableSheet(
            initialChildSize: 0.60,
            minChildSize: 0.60,
            maxChildSize: 0.92,
            builder: (context, scroll) => Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.sheet,
                boxShadow: AppShadows.sheet,
              ),
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
                children: [
                  const Center(child: SheetGrabber()),
                  const SizedBox(height: 18),
                  Text('Where to?',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 14),
                  _SearchCard(
                    fromLabel: query.fromLabel,
                    toLabel: query.toLabel,
                    hasDestination: query.isReady,
                    onSwap: () => ref.read(searchProvider.notifier).swap(),
                    onEditTo: () => _openDestinationSearch(context, ref),
                  ),
                  const SizedBox(height: 22),
                  _ModeFilter(
                    modes: _modes,
                    selected: query.modes,
                    onTap: (m) => ref.read(searchProvider.notifier).toggleMode(m),
                    onAll: () => ref.read(searchProvider.notifier).toggleMode(TransportMode.all),
                  ),
                  const SizedBox(height: 22),
                  const SectionLabel('Nearest stops'),
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

/// Branded map fallback while the location or tiles resolve.
class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.surfaceAlt,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const RoundelLoader(size: 38),
            const SizedBox(height: 14),
            Text(label,
                style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
          ],
        ),
      );
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
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.field,
            boxShadow: AppShadows.card,
          ),
          child: Column(
            children: [
              _endpointRow(
                dot: _dot(AppColors.primary, circle: true),
                label: 'START',
                value: fromLabel,
                valueColor: AppColors.textStrong,
              ),
              const Padding(
                padding: EdgeInsets.only(left: 42),
                child: Divider(height: 1, color: AppColors.hairline),
              ),
              _endpointRow(
                dot: _dot(AppColors.roundelRed, circle: false),
                label: 'DESTINATION',
                value: toLabel,
                valueColor: hasDestination ? AppColors.textStrong : const Color(0xFFAAB2BC),
                onTap: onEditTo,
              ),
            ],
          ),
        ),
        // Swap — a circular control straddling the divider, the familiar
        // transit pattern (no more thin floating bar).
        Positioned(
          right: 14,
          top: 0,
          bottom: 0,
          child: Center(
            child: Material(
              color: AppColors.blueTint,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onSwap,
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.swap_vert_rounded, color: AppColors.primary, size: 22),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dot(Color color, {required bool circle}) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : BorderRadius.circular(3),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.20), spreadRadius: 4)],
        ),
      );

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
          padding: const EdgeInsets.fromLTRB(15, 14, 56, 14),
          child: Row(
            children: [
              SizedBox(width: 16, child: Center(child: dot)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8)),
                    const SizedBox(height: 1),
                    Text(value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600, color: valueColor)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

/// A horizontal filter of real travel modes, with an "All" reset.
class _ModeFilter extends StatelessWidget {
  const _ModeFilter({
    required this.modes,
    required this.selected,
    required this.onTap,
    required this.onAll,
  });
  final List<TransportMode> modes;
  final Set<TransportMode> selected;
  final ValueChanged<TransportMode> onTap;
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context) {
    final allActive = selected.contains(TransportMode.all);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: SectionLabel('Get around by', padding: EdgeInsets.zero)),
            GestureDetector(
              onTap: allActive ? null : onAll,
              child: Text('All modes',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: allActive ? AppColors.primary : AppColors.muted)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: modes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) => SizedBox(
              width: 74,
              child: ModeChip(
                mode: modes[i],
                selected: selected.contains(modes[i]),
                onTap: () => onTap(modes[i]),
              ),
            ),
          ),
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
                if (i > 0)
                  const Padding(
                    padding: EdgeInsets.only(left: 53),
                    child: Divider(height: 1, color: AppColors.hairline),
                  ),
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
