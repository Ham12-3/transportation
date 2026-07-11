import 'package:latlong2/latlong.dart';
import 'transport_mode.dart';

/// A TfL StopPoint (bus stop, station, pier…) from StopPoint search / nearby.
class StopPoint {
  final String id;
  final String name;
  final String? indicator; // e.g. "Stop D"
  final String? stopLetter;
  final LatLng position;
  final double? distanceMeters;
  final List<TransportMode> modes;
  final List<String> lines;

  const StopPoint({
    required this.id,
    required this.name,
    required this.position,
    this.indicator,
    this.stopLetter,
    this.distanceMeters,
    this.modes = const [],
    this.lines = const [],
  });

  int get walkMinutes {
    final d = distanceMeters ?? 0;
    return (d / 80).round().clamp(1, 99); // ~80 m/min walking pace
  }

  factory StopPoint.fromJson(Map<String, dynamic> j) {
    double? lat = (j['lat'] as num?)?.toDouble();
    double? lon = (j['lon'] as num?)?.toDouble();
    final modes = <TransportMode>[];
    for (final m in (j['modes'] as List? ?? const [])) {
      modes.add(TransportMode.fromTfl(m.toString()));
    }
    final lines = <String>[];
    for (final l in (j['lines'] as List? ?? const [])) {
      final name = (l is Map) ? l['name']?.toString() : l.toString();
      if (name != null) lines.add(name);
    }
    return StopPoint(
      id: (j['id'] ?? j['naptanId'] ?? '').toString(),
      name: (j['commonName'] ?? j['name'] ?? 'Stop').toString(),
      indicator: j['indicator']?.toString(),
      stopLetter: j['stopLetter']?.toString(),
      position: LatLng(lat ?? 51.5074, lon ?? -0.1278),
      distanceMeters: (j['distance'] as num?)?.toDouble(),
      modes: modes,
      lines: lines,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'commonName': name,
        'indicator': indicator,
        'stopLetter': stopLetter,
        'lat': position.latitude,
        'lon': position.longitude,
        'distance': distanceMeters,
        'modes': modes.map((m) => m.tflId).toList(),
        'lines': lines,
      };
}
