import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

import '../models/arrival.dart';
import '../models/journey.dart';
import '../models/journey_plan.dart';
import '../models/stop_point.dart';
import '../models/transport_mode.dart';
import 'api_config.dart';

/// Typed client for the Transport for London Unified API.
///
/// Wraps Journey Planner, StopPoint search / nearby, and live arrivals.
class TflService {
  TflService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: ApiConfig.tflBaseUrl,
              connectTimeout: const Duration(seconds: 25),
              receiveTimeout: const Duration(seconds: 40),
              // TfL returns HTTP 300 (Multiple Choices) for ambiguous locations;
              // accept it so we can resolve the disambiguation ourselves.
              validateStatus: (s) => s != null && s < 400,
            ));

  final Dio _dio;

  Future<Response<dynamic>> _get(String path, [Map<String, dynamic>? q]) {
    return _dio.get(path, queryParameters: {...?q, ...ApiConfig.tflAuth});
  }

  /// Journey Planner — bus + train + walk + cycle route options.
  /// [from] / [to] may be "lat,lon", a StopPoint id, or a free-text place.
  ///
  /// Returns ranked journeys, or — when TfL can't resolve an endpoint uniquely
  /// (HTTP 300) — the list of candidate locations so the user can choose which
  /// one they meant. Nothing is silently picked on their behalf.
  Future<JourneyPlanResult> planJourney({
    required String from,
    required String to,
    List<TransportMode> modes = const [],
    DateTime? when,
    bool arriveBy = false,
  }) async {
    final q = <String, dynamic>{};
    if (modes.isNotEmpty && !modes.contains(TransportMode.all)) {
      q['mode'] = modes
          .where((m) => m != TransportMode.all && m != TransportMode.saved && m != TransportMode.air)
          .map((m) => m.tflId)
          .join(',');
    }
    if (when != null) {
      q['date'] = _yyyymmdd(when);
      q['time'] = _hhmm(when);
      q['timeIs'] = arriveBy ? 'arriving' : 'departing';
    }
    final res = await _get('/Journey/JourneyResults/$from/to/$to', q);
    final data = res.data;
    if (data is! Map) return const JourneyPlanResult();

    final journeys = data['journeys'] as List?;
    if (journeys != null && journeys.isNotEmpty) {
      return JourneyPlanResult(journeys: [
        for (final j in journeys) Journey.fromJson(Map<String, dynamic>.from(j)),
      ]);
    }

    // Ambiguous endpoint — surface the candidate locations (destination first,
    // then origin) for the user to pick from.
    final toOptions = _disambiguationOptions(data['toLocationDisambiguation']);
    if (toOptions.isNotEmpty) {
      return JourneyPlanResult(options: toOptions, ambiguousEnd: AmbiguousEnd.destination);
    }
    final fromOptions = _disambiguationOptions(data['fromLocationDisambiguation']);
    if (fromOptions.isNotEmpty) {
      return JourneyPlanResult(options: fromOptions, ambiguousEnd: AmbiguousEnd.origin);
    }

    return const JourneyPlanResult(); // genuinely no routes
  }

  /// Parses a TfL disambiguation block into usable candidate locations,
  /// ranked as TfL returned them and keeping only ones with coordinates.
  List<PlaceOption> _disambiguationOptions(dynamic disambiguation) {
    if (disambiguation is! Map) return const [];
    final options = disambiguation['disambiguationOptions'] as List?;
    if (options == null || options.isEmpty) return const [];
    final out = <PlaceOption>[];
    for (final o in options) {
      if (o is Map) {
        final p = PlaceOption.fromTflOption(o);
        if (p.hasCoord) out.add(p);
      }
    }
    return out;
  }

  /// StopPoints within [radius] metres of a coordinate, nearest first.
  Future<List<StopPoint>> nearbyStops({
    required LatLng center,
    int radius = 650,
    List<TransportMode> modes = const [
      TransportMode.bus,
      TransportMode.tube,
      TransportMode.rail,
      TransportMode.tram,
    ],
  }) async {
    final res = await _get('/StopPoint', {
      'lat': center.latitude,
      'lon': center.longitude,
      'radius': radius,
      'stopTypes':
          'NaptanMetroStation,NaptanRailStation,NaptanPublicBusCoachTram,NaptanFerryPort',
      'modes': modes.map((m) => m.tflId).join(','),
    });
    final stops = (res.data['stopPoints'] as List? ?? const []);
    final list = [
      for (final s in stops) StopPoint.fromJson(Map<String, dynamic>.from(s)),
    ];
    list.sort((a, b) => (a.distanceMeters ?? 0).compareTo(b.distanceMeters ?? 0));
    return list;
  }

  /// Free-text StopPoint search for the start/end autocomplete fields.
  Future<List<StopPoint>> searchStops(String query) async {
    if (query.trim().isEmpty) return const [];
    final res = await _get('/StopPoint/Search', {'query': query, 'maxResults': 12});
    final matches = (res.data['matches'] as List? ?? const []);
    return [
      for (final m in matches)
        StopPoint(
          id: (m['id'] ?? '').toString(),
          name: (m['name'] ?? '').toString(),
          position: LatLng(
            (m['lat'] as num?)?.toDouble() ?? 51.5074,
            (m['lon'] as num?)?.toDouble() ?? -0.1278,
          ),
          modes: [for (final x in (m['modes'] as List? ?? const [])) TransportMode.fromTfl(x.toString())],
        ),
    ];
  }

  /// Live arrival predictions for a StopPoint.
  Future<List<Arrival>> arrivals(String stopId) async {
    final res = await _get('/StopPoint/$stopId/Arrivals');
    final list = [
      for (final a in (res.data as List? ?? const []))
        Arrival.fromJson(Map<String, dynamic>.from(a)),
    ];
    list.sort((a, b) => a.timeToStationSeconds.compareTo(b.timeToStationSeconds));
    return list.take(6).toList();
  }
}

String _two(int n) => n.toString().padLeft(2, '0');
String _yyyymmdd(DateTime d) => '${d.year}${_two(d.month)}${_two(d.day)}';
String _hhmm(DateTime d) => '${_two(d.hour)}${_two(d.minute)}';
