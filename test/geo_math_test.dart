import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tube_london/ar/geo_math.dart';

void main() {
  group('GeoMath.distance', () {
    test('is ~0 for identical points', () {
      const p = LatLng(51.5074, -0.1278);
      expect(GeoMath.distance(p, p), lessThan(0.001));
    });

    test('matches a known short London distance within tolerance', () {
      // Blackfriars → St Paul's is ~650 m as the crow flies.
      const a = LatLng(51.5116, -0.1036);
      const b = LatLng(51.5138, -0.0984);
      final d = GeoMath.distance(a, b);
      expect(d, greaterThan(400));
      expect(d, lessThan(900));
    });
  });

  group('GeoMath.bearing', () {
    test('due north is ~0°', () {
      const a = LatLng(51.50, -0.10);
      const b = LatLng(51.51, -0.10);
      expect(GeoMath.bearing(a, b), closeTo(0, 1));
    });

    test('due east is ~90°', () {
      const a = LatLng(51.50, -0.10);
      const b = LatLng(51.50, -0.09);
      expect(GeoMath.bearing(a, b), closeTo(90, 1));
    });
  });

  group('GeoMath.relativeAngle', () {
    test('wraps to shortest signed turn', () {
      expect(GeoMath.relativeAngle(350, 10), closeTo(20, 0.001)); // right
      expect(GeoMath.relativeAngle(10, 350), closeTo(-20, 0.001)); // left
      expect(GeoMath.relativeAngle(0, 0), closeTo(0, 0.001));
    });
  });
}
