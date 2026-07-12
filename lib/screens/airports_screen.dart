import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../models/aircraft.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/common.dart';
import '../widgets/state_views.dart';

/// S6 — Air. Live air-fleet map over London with tap-for-detail aircraft,
/// auto-refreshing every 15s via [airFleetProvider].
class AirportsScreen extends ConsumerStatefulWidget {
  const AirportsScreen({super.key});
  @override
  ConsumerState<AirportsScreen> createState() => _AirportsScreenState();
}

class _AirportsScreenState extends ConsumerState<AirportsScreen> {
  final _map = MapController();
  Aircraft? _selected;

  @override
  Widget build(BuildContext context) {
    final fleet = ref.watch(airFleetProvider);
    final top = MediaQuery.of(context).padding.top;
    final list = fleet.asData?.value ?? const <Aircraft>[];

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      // StackFit.expand makes the stack fill the screen even though its only
      // non-positioned content is the map; without it the stack collapsed to
      // the header's height, hiding the map and pushing the bottom legend up.
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _map,
              options: const MapOptions(
                initialCenter: LatLng(51.47, -0.32), // Heathrow-ish
                initialZoom: 9.4,
                backgroundColor: AppColors.surfaceAlt,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                  userAgentPackageName: 'com.tubelondon.tube_london',
                  subdomains: const ['a', 'b', 'c', 'd'],
                ),
                MarkerLayer(
                  markers: [
                    for (final ac in list)
                      Marker(
                        point: ac.position,
                        width: 34,
                        height: 34,
                        child: GestureDetector(
                          onTap: () => setState(() => _selected = ac),
                          child: Transform.rotate(
                            angle: ((ac.headingDegrees ?? 0) * math.pi / 180),
                            child: Icon(
                              Icons.flight_rounded,
                              size: _selected?.icao24 == ac.icao24 ? 30 : 22,
                              color: ac.onGround ? AppColors.muted : _altColor(ac.altitudeMeters),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Header — pinned to the top edge.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
            padding: EdgeInsets.fromLTRB(16, top + 12, 16, 14),
            decoration: const BoxDecoration(
              color: AppColors.navy,
              boxShadow: [BoxShadow(color: Color(0x40000E4D), blurRadius: 16, offset: Offset(0, 4))],
            ),
            child: Row(
              children: [
                const Icon(Icons.flight_takeoff_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text('Air Fleet · London',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
                const Spacer(),
                fleet.when(
                  data: (l) => _pill('${l.length} live', dot: AppColors.green),
                  loading: () => _pill('scanning', dot: AppColors.amber),
                  error: (_, _) => _pill('offline', dot: AppColors.red),
                ),
              ],
            ),
          ),
          ),

          // Centered state when we have no aircraft to show yet. Priority:
          // error → empty → loading, so they never appear at the same time.
          if (list.isEmpty)
            if (fleet.hasError)
              Center(
                child: MessageView(
                  icon: Icons.cloud_off_rounded,
                  title: 'Live fleet unavailable',
                  message:
                      'The open flight feed is busy or rate-limited. It keeps retrying every 15 seconds.',
                  actionLabel: 'Retry now',
                  onAction: () => ref.invalidate(airFleetProvider),
                  tint: AppColors.red,
                ),
              )
            else if (fleet.isLoading)
              const Center(child: LoadingView(label: 'Scanning London airspace…'))
            else
              Center(
                child: MessageView(
                  icon: Icons.flight_rounded,
                  title: 'No aircraft overhead',
                  message: 'Nothing in the London box right now. It refreshes every 15 seconds.',
                  actionLabel: 'Refresh',
                  onAction: () => ref.invalidate(airFleetProvider),
                ),
              ),

          // When planes ARE on screen but a background refresh failed, keep it
          // quiet — a small strip rather than covering the map.
          if (list.isNotEmpty && fleet.hasError)
            Positioned(
              left: 20,
              right: 20,
              bottom: 88,
              child: AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(children: [
                  const Icon(Icons.cloud_off_rounded, color: AppColors.red, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                      child: Text('Feed busy — showing last positions',
                          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
                ]),
              ),
            ),

          // Altitude legend — only once we have planes to explain
          if (list.isNotEmpty && _selected == null)
            Positioned(left: 16, right: 16, bottom: 24, child: const _AltitudeLegend()),

          // Detail sheet
          if (_selected != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: _AircraftDetail(
                aircraft: _selected!,
                onClose: () => setState(() => _selected = null),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pill(String text, {required Color dot}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: AppRadius.pill),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 7),
          Text(text,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
        ]),
      );

  Color _altColor(double? m) {
    if (m == null) return AppColors.primary;
    if (m < 1000) return AppColors.amber;
    if (m < 4000) return AppColors.primary;
    return AppColors.navy;
  }
}

/// A compact key for the altitude colour bands on the map.
class _AltitudeLegend extends StatelessWidget {
  const _AltitudeLegend();
  @override
  Widget build(BuildContext context) {
    Widget item(Color c, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.flight_rounded, size: 15, color: c),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.text)),
        ]);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          item(AppColors.amber, 'Low'),
          item(AppColors.primary, 'Cruise'),
          item(AppColors.navy, 'High'),
          item(AppColors.muted, 'On ground'),
        ],
      ),
    );
  }
}

class _AircraftDetail extends StatelessWidget {
  const _AircraftDetail({required this.aircraft, required this.onClose});
  final Aircraft aircraft;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final a = aircraft;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(Icons.flight_rounded, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.callsign.isEmpty ? a.icao24.toUpperCase() : a.callsign,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    Text(a.originCountry ?? 'Unknown origin',
                        style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 20,
            runSpacing: 12,
            children: [
              _stat('Altitude', a.altitudeFeet == null ? '—' : '${a.altitudeFeet!.round()} ft'),
              _stat('Speed', a.speedKnots == null ? '—' : '${a.speedKnots!.round()} kt'),
              _stat('Heading', a.headingDegrees == null ? '—' : '${a.headingDegrees!.round()}°'),
              _stat('Status', a.onGround ? 'On ground' : 'Airborne'),
              _stat('ICAO24', a.icao24.toUpperCase()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textStrong)),
        ],
      );
}
