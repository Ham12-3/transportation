import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/journey.dart';
import '../models/transport_mode.dart';
import 'geo_math.dart';

/// A single navigation waypoint with a synthesized turn instruction.
class NavPoint {
  final LatLng location;
  final String instruction;
  final String turn; // LEFT / RIGHT / STRAIGHT
  final TransportMode legMode;
  final String legLabel;
  NavPoint(this.location, this.instruction, this.turn, this.legMode, this.legLabel);
}

/// Fuses GPS + compass to drive AR turn-by-turn: tracks position along the
/// journey polyline, advances through legs, and exposes the relative bearing
/// used to place overlays in AR space.
class NavController extends ChangeNotifier {
  NavController(this.journey) {
    _build();
  }

  final Journey journey;
  final List<NavPoint> _points = [];

  StreamSubscription<Position>? _posSub;
  StreamSubscription<CompassEvent>? _compassSub;

  LatLng? position;
  double heading = 0; // device heading, degrees from north
  int _index = 0;
  bool arrived = false;

  // Derived, read by the UI.
  double distanceToNext = 0; // metres to the next turn/waypoint
  double remainingMeters = 0;
  int remainingMinutes = 0;
  DateTime? eta;

  NavPoint? get next => _index < _points.length ? _points[_index] : null;
  NavPoint? get following => _index + 1 < _points.length ? _points[_index + 1] : null;

  /// Bearing from the user to the next waypoint (0..360).
  double get bearingToNext =>
      (position != null && next != null) ? GeoMath.bearing(position!, next!.location) : heading;

  /// Signed angle (-180..180) between where the user faces and the next turn.
  /// Drives horizontal placement of the AR chevrons.
  double get relativeAngle => GeoMath.relativeAngle(heading, bearingToNext);

  void _build() {
    final path = journey.fullPath;
    if (path.length >= 2) {
      // Synthesize turn instructions at significant bearing changes.
      int legIdx = 0;
      int consumed = 0;
      for (var i = 0; i < path.length; i++) {
        // Map point i back to a leg for label/mode context.
        while (legIdx < journey.legs.length - 1 &&
            consumed + journey.legs[legIdx].path.length <= i) {
          consumed += journey.legs[legIdx].path.length;
          legIdx++;
        }
        final leg = journey.legs.isNotEmpty ? journey.legs[legIdx] : null;
        String turn = 'STRAIGHT';
        String instr = 'Continue';
        if (i > 0 && i < path.length - 1) {
          final b1 = GeoMath.bearing(path[i - 1], path[i]);
          final b2 = GeoMath.bearing(path[i], path[i + 1]);
          final delta = GeoMath.relativeAngle(b1, b2);
          if (delta.abs() < 25) continue; // not a real turn — skip
          turn = delta > 0 ? 'RIGHT' : 'LEFT';
          instr = 'Turn ${delta > 0 ? 'right' : 'left'}';
        } else if (i == path.length - 1) {
          instr = 'Arrive at destination';
        } else {
          instr = leg?.mode == TransportMode.walking ? 'Head straight' : 'Continue';
        }
        _points.add(NavPoint(
          path[i],
          leg != null && leg.arrivalPoint.isNotEmpty && i == path.length - 1
              ? 'Arrive · ${leg.arrivalPoint}'
              : instr,
          turn,
          leg?.mode ?? TransportMode.walking,
          leg?.lineName ?? leg?.mode.label ?? 'Route',
        ));
      }
    }
    if (_points.isEmpty) {
      // Fallback: single destination waypoint.
      final dest = path.isNotEmpty ? path.last : const LatLng(51.5074, -0.1278);
      _points.add(NavPoint(dest, 'Head to destination', 'STRAIGHT', TransportMode.walking, 'Route'));
    }
  }

  Future<void> start() async {
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2,
      ),
    ).listen(_onPosition);

    _compassSub = FlutterCompass.events?.listen((e) {
      if (e.heading != null) {
        heading = (e.heading! + 360) % 360;
        notifyListeners();
      }
    });
  }

  void _onPosition(Position p) {
    position = LatLng(p.latitude, p.longitude);
    _recompute();
    notifyListeners();
  }

  void _recompute() {
    if (position == null || next == null) return;
    distanceToNext = GeoMath.distance(position!, next!.location);

    // Advance past the waypoint once we're within ~12 m.
    if (distanceToNext < 12 && _index < _points.length - 1) {
      _index++;
      distanceToNext = GeoMath.distance(position!, next!.location);
    }
    if (_index >= _points.length - 1 && distanceToNext < 15) {
      arrived = true;
    }

    // Remaining distance = to next + sum of the remaining legs of the path.
    double rem = distanceToNext;
    for (var i = _index; i < _points.length - 1; i++) {
      rem += GeoMath.distance(_points[i].location, _points[i + 1].location);
    }
    remainingMeters = rem;
    // Assume ~1.35 m/s walking; transit legs are faster but this is a live nav walk-guide.
    remainingMinutes = (rem / 1.35 / 60).ceil();
    eta = DateTime.now().add(Duration(minutes: remainingMinutes));
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _compassSub?.cancel();
    super.dispose();
  }
}
