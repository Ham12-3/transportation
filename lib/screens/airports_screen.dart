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

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      body: Stack(
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
                    for (final ac in fleet.asData?.value ?? const [])
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

          // Header
          Container(
            padding: EdgeInsets.fromLTRB(16, top + 10, 16, 14),
            decoration: const BoxDecoration(
              color: AppColors.navy,
              boxShadow: [BoxShadow(color: Color(0x40173B6E), blurRadius: 16, offset: Offset(0, 4))],
            ),
            child: Row(
              children: [
                const Icon(Icons.flight_rounded, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Air Fleet · London',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const Spacer(),
                fleet.when(
                  data: (list) => _pill('${list.length} live'),
                  loading: () => _pill('…'),
                  error: (_, _) => _pill('offline'),
                ),
              ],
            ),
          ),

          // Loading / error banner
          if (fleet.isLoading)
            const Positioned(bottom: 120, left: 0, right: 0, child: Center(child: LoadingView())),
          if (fleet.hasError)
            Positioned(
              bottom: 130,
              left: 24,
              right: 24,
              child: AppCard(
                child: Row(children: [
                  const Icon(Icons.cloud_off_rounded, color: AppColors.red),
                  const SizedBox(width: 12),
                  const Expanded(
                      child: Text('Live fleet feed unavailable. Retrying…',
                          style: TextStyle(fontWeight: FontWeight.w600))),
                  TextButton(
                      onPressed: () => ref.invalidate(airFleetProvider), child: const Text('Retry')),
                ]),
              ),
            ),

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

  Widget _pill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: AppRadius.pill),
        child: Text(text,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
      );

  Color _altColor(double? m) {
    if (m == null) return AppColors.primary;
    if (m < 1000) return AppColors.amber;
    if (m < 4000) return AppColors.primary;
    return AppColors.navy;
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
