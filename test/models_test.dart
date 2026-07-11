import 'package:flutter_test/flutter_test.dart';
import 'package:tube_london/models/aircraft.dart';
import 'package:tube_london/models/arrival.dart';
import 'package:tube_london/models/journey.dart';
import 'package:tube_london/models/transport_mode.dart';

void main() {
  test('TransportMode.fromTfl maps TfL mode names', () {
    expect(TransportMode.fromTfl('tube'), TransportMode.tube);
    expect(TransportMode.fromTfl('national-rail'), TransportMode.rail);
    expect(TransportMode.fromTfl('london-overground'), TransportMode.rail);
    expect(TransportMode.fromTfl('walking'), TransportMode.walking);
    expect(TransportMode.fromTfl(null), TransportMode.bus);
  });

  test('Arrival parses timeToStation into minutes + ETA label', () {
    final a = Arrival.fromJson({
      'id': '1',
      'lineName': '63',
      'destinationName': 'Honor Oak',
      'timeToStation': 65,
      'modeName': 'bus',
    });
    expect(a.minutes, 1);
    expect(a.etaLabel, '1 min');

    final due = Arrival.fromJson({'timeToStation': 20});
    expect(due.etaLabel, 'Due');
  });

  test('Journey computes fare label, badges and walk calories', () {
    final j = Journey.fromJson({
      'duration': 24,
      'fare': {'totalCost': 230}, // pence
      'legs': [
        {
          'duration': 7,
          'mode': {'name': 'walking'},
          'departurePoint': {'commonName': 'A'},
          'arrivalPoint': {'commonName': 'B'},
        },
        {
          'duration': 17,
          'mode': {'name': 'tube'},
          'routeOptions': [
            {'name': 'Victoria'}
          ],
          'departurePoint': {'commonName': 'B'},
          'arrivalPoint': {'commonName': 'C'},
        },
      ],
    });
    expect(j.fareLabel, '£2.30');
    expect(j.walkMinutes, 7);
    expect(j.walkCalories, 28);
    expect(j.lineBadges, contains('Victoria'));
  });

  test('Aircraft parses an OpenSky state vector', () {
    final s = [
      'abc123', 'BAW702 ', 'United Kingdom', 0, 0,
      -0.45, 51.47, 10000.0, false, 230.0, 90.0, 0.0, null, 10500.0,
    ];
    final ac = Aircraft.fromOpenSkyState(s)!;
    expect(ac.icao24, 'abc123');
    expect(ac.callsign, 'BAW702');
    expect(ac.position.latitude, closeTo(51.47, 0.001));
    expect(ac.headingDegrees, 90.0);
    expect(ac.onGround, false);
  });
}
