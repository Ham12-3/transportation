import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

/// Geodesic helpers for placing AR overlays at real-world bearings and
/// advancing through route legs as the user walks.
class GeoMath {
  static const double _earthRadius = 6371000; // metres

  static double _deg2rad(double d) => d * math.pi / 180.0;
  static double _rad2deg(double r) => r * 180.0 / math.pi;

  /// Great-circle distance between two points, in metres.
  static double distance(LatLng a, LatLng b) {
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLon = _deg2rad(b.longitude - a.longitude);
    final la1 = _deg2rad(a.latitude);
    final la2 = _deg2rad(b.latitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(la1) * math.cos(la2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    return 2 * _earthRadius * math.asin(math.min(1, math.sqrt(h)));
  }

  /// Initial bearing (0..360, clockwise from true north) from [a] to [b].
  static double bearing(LatLng a, LatLng b) {
    final la1 = _deg2rad(a.latitude);
    final la2 = _deg2rad(b.latitude);
    final dLon = _deg2rad(b.longitude - a.longitude);
    final y = math.sin(dLon) * math.cos(la2);
    final x = math.cos(la1) * math.sin(la2) -
        math.sin(la1) * math.cos(la2) * math.cos(dLon);
    return (_rad2deg(math.atan2(y, x)) + 360) % 360;
  }

  /// Smallest signed angle (-180..180) to turn from [heading] to [target].
  /// Positive = target is to the right of current heading.
  static double relativeAngle(double heading, double target) {
    var diff = (target - heading + 540) % 360 - 180;
    return diff;
  }
}
