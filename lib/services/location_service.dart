import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Wraps geolocator for permission handling + live position streaming.
class LocationService {
  /// Central London fallback (Blackfriars) when location is unavailable.
  static const LatLng londonFallback = LatLng(51.5116, -0.1036);

  Future<bool> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.always || perm == LocationPermission.whileInUse;
  }

  Future<LatLng> currentOrFallback() async {
    try {
      if (!await ensurePermission()) return londonFallback;
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      return LatLng(p.latitude, p.longitude);
    } catch (_) {
      return londonFallback;
    }
  }

  Stream<Position> positionStream() => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 3,
        ),
      );
}
