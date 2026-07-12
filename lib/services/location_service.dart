import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Wraps geolocator for permission handling + live position streaming.
class LocationService {
  /// Absolute last-resort centre (central London) used only when the device
  /// reports no position at all — never in preference to a real fix.
  static const LatLng londonFallback = LatLng(51.5072, -0.1276);

  Future<bool> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.always || perm == LocationPermission.whileInUse;
  }

  /// The device's current position, resolved as robustly as possible:
  ///   1. a fresh fix, but capped so it can never hang the UI;
  ///   2. the last-known position (what a stationary emulator actually reports);
  ///   3. only then the central-London constant.
  ///
  /// Steps 1–2 mean the app tracks wherever the device really is, instead of
  /// silently snapping to a hardcoded point whenever a fresh fix is slow.
  Future<LatLng> currentOrFallback() async {
    try {
      if (!await ensurePermission()) {
        return await _lastKnownOr(londonFallback);
      }
      try {
        final p = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 6),
          ),
        );
        return LatLng(p.latitude, p.longitude);
      } on TimeoutException {
        return await _lastKnownOr(londonFallback);
      } catch (_) {
        return await _lastKnownOr(londonFallback);
      }
    } catch (_) {
      return londonFallback;
    }
  }

  Future<LatLng> _lastKnownOr(LatLng fallback) async {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return LatLng(last.latitude, last.longitude);
    } catch (_) {/* ignore */}
    return fallback;
  }

  Stream<Position> positionStream() => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 3,
        ),
      );
}
