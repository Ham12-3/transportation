import 'package:latlong2/latlong.dart';
import 'transport_mode.dart';

/// A single turn instruction within a leg (used for AR turn-by-turn).
class NavInstruction {
  final String summary; // "Turn right onto Fleet Street"
  final String? detailed;
  final int distanceMeters;
  final LatLng? location;
  final String turnDirection; // LEFT / RIGHT / STRAIGHT / ...

  const NavInstruction({
    required this.summary,
    required this.distanceMeters,
    this.detailed,
    this.location,
    this.turnDirection = 'STRAIGHT',
  });

  factory NavInstruction.fromJson(Map<String, dynamic> j, {LatLng? loc}) => NavInstruction(
        summary: (j['summary'] ?? j['detailed'] ?? 'Continue').toString(),
        detailed: j['detailed']?.toString(),
        distanceMeters: (j['distanceMeters'] as num?)?.toInt() ?? 0,
        location: loc,
        turnDirection: (j['turnDirection'] ?? 'STRAIGHT').toString(),
      );
}

/// One leg of a journey (walk, ride, transfer…).
class JourneyLeg {
  final TransportMode mode;
  final String instruction; // "CMX1 · Fleet Street"
  final String? lineName; // badge text e.g. "CMX1", "4", "381"
  final String departurePoint;
  final String arrivalPoint;
  final int durationMinutes;
  final List<NavInstruction> steps;
  final List<LatLng> path; // decoded polyline points
  final bool isFree;

  const JourneyLeg({
    required this.mode,
    required this.instruction,
    required this.departurePoint,
    required this.arrivalPoint,
    required this.durationMinutes,
    this.lineName,
    this.steps = const [],
    this.path = const [],
    this.isFree = false,
  });

  factory JourneyLeg.fromJson(Map<String, dynamic> j) {
    final modeName = (j['mode']?['name'] ?? j['mode'] ?? 'walking').toString();
    final mode = TransportMode.fromTfl(modeName);

    // Decode the leg geometry (TfL returns a JSON-encoded lineString array).
    final path = <LatLng>[];
    final ls = j['path']?['lineString'];
    if (ls is String && ls.length > 2) {
      try {
        final cleaned = ls.replaceAll('[', '').replaceAll(']', '').split(',');
        for (var i = 0; i + 1 < cleaned.length; i += 2) {
          path.add(LatLng(double.parse(cleaned[i]), double.parse(cleaned[i + 1])));
        }
      } catch (_) {/* ignore malformed geometry */}
    }

    final steps = <NavInstruction>[];
    for (final s in (j['path']?['stopPoints'] as List? ?? const [])) {
      // stopPoints carry no turn geometry; keep as coarse waypoints.
      steps.add(NavInstruction(summary: (s['name'] ?? '').toString(), distanceMeters: 0));
    }
    // TfL also nests a stepwise instruction list on the leg's `instruction`.
    final instr = j['instruction'];
    final stepList = instr is Map ? instr['steps'] as List? : null;
    for (final st in (stepList ?? const [])) {
      steps.add(NavInstruction.fromJson(Map<String, dynamic>.from(st)));
    }

    final routeOptions = (j['routeOptions'] as List?) ?? const [];
    String? lineName;
    if (routeOptions.isNotEmpty) {
      lineName = routeOptions.first['name']?.toString();
    }

    return JourneyLeg(
      mode: mode,
      instruction: (instr is Map ? instr['summary'] : instr)?.toString() ?? mode.label,
      lineName: lineName,
      departurePoint: (j['departurePoint']?['commonName'] ?? '').toString(),
      arrivalPoint: (j['arrivalPoint']?['commonName'] ?? '').toString(),
      durationMinutes: (j['duration'] as num?)?.toInt() ?? 0,
      steps: steps,
      path: path,
      isFree: false,
    );
  }
}

/// A ranked journey option in the results list.
class Journey {
  final int durationMinutes;
  final DateTime? startDateTime;
  final DateTime? arrivalDateTime;
  final List<JourneyLeg> legs;
  final double? fareGbp;

  const Journey({
    required this.durationMinutes,
    required this.legs,
    this.startDateTime,
    this.arrivalDateTime,
    this.fareGbp,
  });

  /// Unique transit line badges in order (skips walking).
  List<String> get lineBadges => [
        for (final l in legs)
          if (l.mode != TransportMode.walking)
            l.lineName ?? l.mode.label,
      ];

  List<TransportMode> get modes => legs.map((l) => l.mode).toList();

  /// All geometry flattened for polyline rendering.
  List<LatLng> get fullPath => [for (final l in legs) ...l.path];

  int get walkMinutes =>
      legs.where((l) => l.mode == TransportMode.walking).fold(0, (a, l) => a + l.durationMinutes);

  /// Rough calorie estimate for the walking portion (~4 cal/min brisk walk).
  int get walkCalories => walkMinutes * 4;

  String? get fareLabel {
    if (fareGbp == null) return null;
    if (fareGbp == 0) return 'FREE';
    return '£${fareGbp!.toStringAsFixed(2)}';
  }

  factory Journey.fromJson(Map<String, dynamic> j) {
    final legs = <JourneyLeg>[];
    for (final l in (j['legs'] as List? ?? const [])) {
      legs.add(JourneyLeg.fromJson(Map<String, dynamic>.from(l)));
    }
    double? fare;
    final f = j['fare'];
    if (f is Map && f['totalCost'] != null) {
      fare = (f['totalCost'] as num).toDouble() / 100.0;
    }
    return Journey(
      durationMinutes: (j['duration'] as num?)?.toInt() ?? 0,
      startDateTime: DateTime.tryParse(j['startDateTime']?.toString() ?? ''),
      arrivalDateTime: DateTime.tryParse(j['arrivalDateTime']?.toString() ?? ''),
      legs: legs,
      fareGbp: fare,
    );
  }
}
