import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_colors.dart';

/// A styled 2D map (flutter_map) with a blue route polyline and markers.
///
/// Uses CartoDB Positron tiles for the clean, light aesthetic in the design.
/// No API key required.
class MapView extends StatelessWidget {
  const MapView({
    super.key,
    required this.center,
    this.zoom = 14,
    this.route = const [],
    this.markers = const [],
    this.controller,
    this.interactive = true,
    this.onMapReady,
  });

  final LatLng center;
  final double zoom;
  final List<LatLng> route;
  final List<Marker> markers;
  final MapController? controller;
  final bool interactive;
  final VoidCallback? onMapReady;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        onMapReady: onMapReady,
        backgroundColor: AppColors.surfaceAlt,
        interactionOptions: InteractionOptions(
          flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: dark
              ? 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
              : 'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
          userAgentPackageName: 'com.tubelondon.tube_london',
          retinaMode: RetinaMode.isHighDensity(context),
          subdomains: const ['a', 'b', 'c', 'd'],
        ),
        if (route.length >= 2)
          PolylineLayer(polylines: [
            // White casing under the blue line, matching the design.
            Polyline(points: route, strokeWidth: 9, color: Colors.white),
            Polyline(points: route, strokeWidth: 4.5, color: AppColors.primary),
          ]),
        if (markers.isNotEmpty) MarkerLayer(markers: markers),
      ],
    );
  }
}

/// A "You are here" pulsing location dot marker.
Marker userLocationMarker(LatLng at) => Marker(
      point: at,
      width: 34,
      height: 34,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: const [
            BoxShadow(color: Color(0x301A6FEB), blurRadius: 0, spreadRadius: 6),
          ],
        ),
      ),
    );

/// A labelled destination / origin pin (blue End, navy Start).
Marker labelPin(LatLng at, String label, {Color color = AppColors.primary}) => Marker(
      point: at,
      width: 80,
      height: 40,
      alignment: Alignment.topCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(9),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
      ),
    );

/// A simple round stop marker (red dot with white ring).
Marker stopDot(LatLng at, {Color color = AppColors.red}) => Marker(
      point: at,
      width: 16,
      height: 16,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
