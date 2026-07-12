import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

import '../models/aircraft.dart';
import 'api_config.dart';

/// A geographic bounding box for querying live aircraft.
class GeoBounds {
  final double minLat, maxLat, minLon, maxLon;
  const GeoBounds(this.minLat, this.maxLat, this.minLon, this.maxLon);

  /// Greater London + the major airports (Heathrow, Gatwick, Stansted, Luton, City).
  static const GeoBounds london = GeoBounds(51.20, 51.75, -0.60, 0.30);
}

/// Source-agnostic contract for live air-fleet data. Swap the implementation
/// (OpenSky today, a bespoke feed tomorrow) without touching the UI/providers.
abstract class AirFleetService {
  Future<List<Aircraft>> statesInBounds(GeoBounds bounds);

  /// Chooses an implementation from build-time config.
  ///
  /// Default is the free, key-less adsb.lol community feed — it needs no
  /// account and isn't credit-throttled like anonymous OpenSky. OpenSky is
  /// used only when credentials are supplied; a bespoke URL wins over both.
  factory AirFleetService.fromConfig({Dio? dio}) {
    if (ApiConfig.airFleetBaseUrl.isNotEmpty) {
      return GenericAirFleetService(dio: dio);
    }
    if (ApiConfig.openSkyUser.isNotEmpty) {
      return OpenSkyAirFleetService(dio: dio);
    }
    return AdsbLolAirFleetService(dio: dio);
  }
}

/// Free community ADS-B feed (https://adsb.lol) — no API key, no account, and
/// far more generous than anonymous OpenSky. Queries aircraft within a radius
/// of the box centre.
class AdsbLolAirFleetService implements AirFleetService {
  AdsbLolAirFleetService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://api.adsb.lol/v2',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              headers: const {'User-Agent': 'tube-london-app/1.0'},
            ));

  final Dio _dio;

  @override
  Future<List<Aircraft>> statesInBounds(GeoBounds b) async {
    final lat = (b.minLat + b.maxLat) / 2;
    final lon = (b.minLon + b.maxLon) / 2;
    final dist = _radiusNm(b, lat);
    final res = await _dio
        .get('/lat/${lat.toStringAsFixed(4)}/lon/${lon.toStringAsFixed(4)}/dist/$dist');
    final list = (res.data['ac'] as List? ?? const []);
    final out = <Aircraft>[];
    for (final a in list) {
      final ac = Aircraft.fromAdsb(Map<String, dynamic>.from(a as Map));
      if (ac != null) out.add(ac);
    }
    return out;
  }

  /// Radius (nautical miles) that circumscribes the bounding box, capped at the
  /// API maximum of 250nm.
  int _radiusNm(GeoBounds b, double lat) {
    final latNm = (b.maxLat - b.minLat) * 60;
    final lonNm = (b.maxLon - b.minLon) * 60 * math.cos(lat * math.pi / 180);
    final halfDiagonal = math.sqrt(latNm * latNm + lonNm * lonNm) / 2;
    return (halfDiagonal + 3).clamp(10, 250).round();
  }
}

/// OpenSky Network implementation (https://opensky-network.org).
class OpenSkyAirFleetService implements AirFleetService {
  OpenSkyAirFleetService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: ApiConfig.openSkyBaseUrl,
              connectTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 20),
            ));

  final Dio _dio;

  @override
  Future<List<Aircraft>> statesInBounds(GeoBounds b) async {
    final options = (ApiConfig.openSkyUser.isNotEmpty)
        ? Options(headers: {
            'Authorization': _basic(ApiConfig.openSkyUser, ApiConfig.openSkyPass),
          })
        : null;
    final res = await _dio.get(
      '/states/all',
      queryParameters: {
        'lamin': b.minLat,
        'lamax': b.maxLat,
        'lomin': b.minLon,
        'lomax': b.maxLon,
      },
      options: options,
    );
    final states = (res.data['states'] as List? ?? const []);
    final out = <Aircraft>[];
    for (final s in states) {
      final ac = Aircraft.fromOpenSkyState(List<dynamic>.from(s));
      if (ac != null) out.add(ac);
    }
    return out;
  }

  String _basic(String u, String p) => 'Basic ${base64Encode(utf8.encode('$u:$p'))}';
}

/// Adapter for a provided/bespoke air-fleet endpoint returning GeoJSON-ish
/// `{ "states": [ {icao24, callsign, lat, lon, altitude, velocity, heading} ] }`.
class GenericAirFleetService implements AirFleetService {
  GenericAirFleetService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: ApiConfig.airFleetBaseUrl,
              headers: {
                if (ApiConfig.airFleetKey.isNotEmpty)
                  'Authorization': 'Bearer ${ApiConfig.airFleetKey}',
              },
            ));

  final Dio _dio;

  @override
  Future<List<Aircraft>> statesInBounds(GeoBounds b) async {
    final res = await _dio.get('/states', queryParameters: {
      'minLat': b.minLat,
      'maxLat': b.maxLat,
      'minLon': b.minLon,
      'maxLon': b.maxLon,
    });
    final states = (res.data['states'] as List? ?? const []);
    return [
      for (final s in states)
        Aircraft(
          icao24: (s['icao24'] ?? '').toString(),
          callsign: (s['callsign'] ?? '').toString().trim(),
          originCountry: s['originCountry']?.toString(),
          position: LatLng(
            (s['lat'] as num).toDouble(),
            (s['lon'] as num).toDouble(),
          ),
          altitudeMeters: (s['altitude'] as num?)?.toDouble(),
          velocityMps: (s['velocity'] as num?)?.toDouble(),
          headingDegrees: (s['heading'] as num?)?.toDouble(),
          onGround: s['onGround'] == true,
        ),
    ];
  }
}
