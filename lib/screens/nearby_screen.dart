import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../models/arrival.dart';
import '../models/stop_point.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/map_view.dart';
import '../widgets/roundel.dart';
import '../widgets/state_views.dart';
import 'stop_arrivals_sheet.dart';

/// S5 — Nearby · Stops & Lines. Radius map with a navy bottom sheet.
class NearbyScreen extends ConsumerWidget {
  const NearbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(currentLocationProvider);
    final nearby = ref.watch(nearbyStopsProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      body: Stack(
        children: [
          Positioned.fill(
            child: location.when(
              data: (loc) => _RadiusMap(center: loc, stops: nearby.asData?.value ?? const []),
              loading: () => const LoadingView(),
              error: (_, _) => const ErrorView(),
            ),
          ),
          // Right floating controls
          Positioned(
            right: 18,
            top: MediaQuery.of(context).padding.top + 70,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'recenter',
                  backgroundColor: AppColors.primary,
                  onPressed: () => ref.invalidate(currentLocationProvider),
                  child: const Icon(Icons.near_me_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.46,
            minChildSize: 0.2,
            maxChildSize: 0.9,
            builder: (context, scroll) => _NearbySheet(nearby: nearby, scroll: scroll),
          ),
        ],
      ),
    );
  }
}

class _RadiusMap extends StatelessWidget {
  const _RadiusMap({required this.center, required this.stops});
  final LatLng center;
  final List<StopPoint> stops;
  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14.5,
        backgroundColor: AppColors.surfaceAlt,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
          userAgentPackageName: 'com.tubelondon.tube_london',
          subdomains: const ['a', 'b', 'c', 'd'],
        ),
        CircleLayer(circles: [
          for (final r in [200.0, 450.0, 700.0])
            CircleMarker(
              point: center,
              radius: r,
              useRadiusInMeter: true,
              color: AppColors.primary.withValues(alpha: 0.04),
              borderColor: AppColors.primary.withValues(alpha: 0.5),
              borderStrokeWidth: 1.4,
            ),
        ]),
        MarkerLayer(markers: [
          userLocationMarker(center),
          for (final s in stops.take(12)) stopDot(s.position),
        ]),
      ],
    );
  }
}

class _NearbySheet extends ConsumerWidget {
  const _NearbySheet({required this.nearby, required this.scroll});
  final AsyncValue<List<StopPoint>> nearby;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.navy,
        borderRadius: AppRadius.sheet,
        boxShadow: [BoxShadow(color: Color(0x4D173B6E), blurRadius: 34, offset: Offset(0, -12))],
      ),
      child: ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
        children: [
          Center(child: SheetGrabber(color: Colors.white.withValues(alpha: 0.35))),
          const SizedBox(height: 14),
          Row(children: [
            const Roundel(size: 26, barColor: Colors.white),
            const SizedBox(width: 11),
            Text('Nearby',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white)),
          ]),
          const SizedBox(height: 16),
          nearby.when(
            loading: () => const Padding(
                padding: EdgeInsets.all(30),
                child: LoadingView(label: 'Finding stops around you…', onDark: true)),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: ErrorView(onDark: true, onRetry: () => ref.invalidate(nearbyStopsProvider)),
            ),
            data: (stops) => stops.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: MessageView(
                        onDark: true,
                        icon: Icons.location_off_rounded,
                        title: 'No stops nearby',
                        message: 'Try moving the map or widening your search.'),
                  )
                : Column(
                    children: [for (final s in stops.take(8)) _StationCard(stop: s)],
                  ),
          ),
        ],
      ),
    );
  }
}

class _StationCard extends ConsumerWidget {
  const _StationCard({required this.stop});
  final StopPoint stop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arrivals = ref.watch(arrivalsProvider(stop.id));
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openArrivals(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Roundel(size: 22),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(stop.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textStrong)),
                    ),
                    Text.rich(TextSpan(children: [
                      const TextSpan(
                          text: 'walk ',
                          style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600, fontSize: 13)),
                      TextSpan(
                          text: '${stop.walkMinutes} min',
                          style: const TextStyle(
                              color: AppColors.textStrong, fontWeight: FontWeight.w800, fontSize: 15)),
                    ])),
                  ],
                ),
                const SizedBox(height: 6),
                arrivals.when(
                  loading: () => const _LineRowSkeleton(),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (list) => Column(
                    children: [
                      for (final a in _byLine(list).take(3)) _LineRow(arrival: a),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Actions — the missing "get around" step: see all arrivals,
                // or plan a route straight to this stop.
                Row(
                  children: [
                    Expanded(
                      child: _CardAction(
                        icon: Icons.access_time_rounded,
                        label: 'Arrivals',
                        onTap: () => _openArrivals(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CardAction(
                        icon: Icons.directions_rounded,
                        label: 'Directions',
                        filled: true,
                        onTap: () => _directions(context, ref),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openArrivals(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => StopArrivalsSheet(stop: stop),
      );

  void _directions(BuildContext context, WidgetRef ref) {
    // TfL Journey Planner resolves raw coordinates directly (no HTTP 300
    // disambiguation), so plan a route from current location to this stop.
    final coord = '${stop.position.latitude},${stop.position.longitude}';
    ref.read(searchProvider.notifier).setTo(coord, label: stop.name);
    context.push('/results');
  }

  // One representative arrival per line for a compact "Lines" view.
  List<Arrival> _byLine(List<Arrival> list) {
    final seen = <String>{};
    return [for (final a in list) if (seen.add(a.lineName)) a];
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.arrival});
  final Arrival arrival;
  @override
  Widget build(BuildContext context) {
    final c = AppColors.lineColor(arrival.lineName);
    final imminent = arrival.minutes <= 2;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(arrival.lineName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
          ),
          Text(arrival.etaLabel,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: imminent ? AppColors.green : AppColors.textStrong)),
        ],
      ),
    );
  }
}

/// A compact action button used on the nearby station cards.
class _CardAction extends StatelessWidget {
  const _CardAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : AppColors.primary;
    return Material(
      color: filled ? AppColors.primary : AppColors.blueTint,
      borderRadius: AppRadius.badge,
      child: InkWell(
        borderRadius: AppRadius.badge,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: fg),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineRowSkeleton extends StatelessWidget {
  const _LineRowSkeleton();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          height: 16,
          child: Row(children: [
            SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.muted)),
            SizedBox(width: 8),
            Text('Loading live times…',
                style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}
