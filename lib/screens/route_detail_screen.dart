import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../models/journey.dart';
import '../models/saved_item.dart';
import '../models/transport_mode.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/buttons.dart';
import '../widgets/chips.dart';
import '../widgets/common.dart';
import '../widgets/map_view.dart';

/// S3 — Route Detail. Map + Quiet/Regular/Fast tabs + GO + step-by-step legs.
class RouteDetailScreen extends ConsumerStatefulWidget {
  const RouteDetailScreen({super.key, required this.journey});
  final Journey journey;
  @override
  ConsumerState<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends ConsumerState<RouteDetailScreen> {
  int _tab = 1; // Quiet / Regular / Fast — "Regular" default

  Journey get j => widget.journey;

  @override
  Widget build(BuildContext context) {
    final path = j.fullPath;
    final start = path.isNotEmpty ? path.first : LocationServiceCenter.london;
    final end = path.isNotEmpty ? path.last : LocationServiceCenter.london;
    final id = 'route_${start.latitude}_${end.latitude}_${j.durationMinutes}';
    final isSaved = ref.watch(savedProvider).any((s) => s.id == id);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: 352, child: _map(path, start, end)),
              Expanded(child: _body()),
            ],
          ),
          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: CircleIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              background: AppColors.primary,
              iconColor: Colors.white,
              size: 44,
              onPressed: () => context.pop(),
            ),
          ),
          // Save
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: CircleIconButton(
              icon: isSaved ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 44,
              onPressed: () => ref.read(savedProvider.notifier).toggle(SavedItem(
                    id: id,
                    kind: SavedKind.route,
                    title: '${j.durationMinutes} min · ${j.lineBadges.take(3).join(" · ")}',
                    subtitle: j.fareLabel ?? 'Route',
                    lat: end.latitude,
                    lon: end.longitude,
                    savedAt: DateTime.now(),
                  )),
            ),
          ),
          // Quiet/Regular/Fast tabs
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 0,
            right: 0,
            child: Center(child: _tabs()),
          ),
          // GO button → AR navigation
          Positioned(
            right: 22,
            top: 352 - 39,
            child: GoButton(onPressed: () => context.push('/ar', extra: j))
                .animate()
                .scale(delay: 200.ms, curve: Curves.easeOutBack),
          ),
        ],
      ),
    );
  }

  Widget _map(List<LatLng> path, LatLng start, LatLng end) {
    if (path.length < 2) {
      return Container(
        color: AppColors.surfaceAlt,
        alignment: Alignment.center,
        child: const Text('Route preview unavailable',
            style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
      );
    }
    return FlutterMap(
      options: MapOptions(
        initialCameraFit: CameraFit.coordinates(
          coordinates: path,
          padding: const EdgeInsets.fromLTRB(40, 90, 40, 60),
        ),
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
        backgroundColor: AppColors.surfaceAlt,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
          userAgentPackageName: 'com.tubelondon.tube_london',
          subdomains: const ['a', 'b', 'c', 'd'],
        ),
        PolylineLayer(polylines: [
          Polyline(points: path, strokeWidth: 10, color: Colors.white),
          Polyline(points: path, strokeWidth: 5, color: AppColors.primary),
        ]),
        MarkerLayer(markers: [
          labelPin(start, 'Start', color: AppColors.navy),
          labelPin(end, 'End', color: AppColors.primary),
        ]),
      ],
    );
  }

  Widget _tabs() {
    const labels = ['Quiet', 'Regular', 'Fast'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.float,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < labels.length; i++)
            GestureDetector(
              onTap: () => setState(() => _tab = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: _tab == i ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(labels[i],
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _tab == i ? Colors.white : AppColors.muted)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _body() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // summary bar
        Container(
          color: const Color(0xFFEDF0F3),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            children: [
              if (j.lineBadges.isNotEmpty) LineBadge(j.lineBadges.first),
              const Spacer(),
              if (j.fareLabel != null)
                Text(j.fareLabel!,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.text, fontSize: 13)),
              const SizedBox(width: 12),
              Row(children: [
                const Icon(Icons.directions_walk_rounded, size: 16, color: AppColors.text),
                const SizedBox(width: 3),
                Text('${j.durationMinutes} min',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.text, fontSize: 13)),
              ]),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          child: Column(
            children: [
              for (var i = 0; i < j.legs.length; i++) _legTile(j.legs[i], i == 0),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legTile(JourneyLeg leg, bool highlighted) {
    final isWalk = leg.mode == TransportMode.walking;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: highlighted && isWalk ? AppColors.blueTint : Colors.white,
        borderRadius: AppRadius.tile,
        boxShadow: highlighted && isWalk ? null : AppShadows.card,
      ),
      child: Row(
        children: [
          if (isWalk)
            Icon(Icons.directions_walk_rounded,
                size: 26, color: highlighted ? AppColors.primary : AppColors.text)
          else
            IconBadge(leg.mode.icon),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isWalk ? 'Walk' : (leg.lineName ?? leg.mode.label),
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: (highlighted && isWalk) ? AppColors.primary : AppColors.textStrong)),
                if (leg.arrivalPoint.isNotEmpty || leg.departurePoint.isNotEmpty)
                  Text(
                      isWalk
                          ? (leg.arrivalPoint.isNotEmpty ? leg.arrivalPoint : leg.departurePoint)
                          : '${leg.departurePoint} → ${leg.arrivalPoint}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: AppColors.text)),
              ],
            ),
          ),
          Text('${leg.durationMinutes} min',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: (highlighted && isWalk) ? AppColors.primary : AppColors.textStrong)),
        ],
      ),
    );
  }
}

/// Small helper to avoid importing LocationService just for a fallback centre.
class LocationServiceCenter {
  static const london = LatLng(51.5116, -0.1036);
}
