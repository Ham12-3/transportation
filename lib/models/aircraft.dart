import 'package:latlong2/latlong.dart';

/// A live aircraft position for the Air Fleet layer. The source is abstracted
/// behind [AirFleetService] so OpenSky can be swapped for another provider.
class Aircraft {
  final String icao24;
  final String callsign;
  final String? originCountry;
  final LatLng position;
  final double? altitudeMeters;
  final double? velocityMps; // ground speed, m/s
  final double? headingDegrees; // true track
  final double? verticalRateMps;
  final bool onGround;

  const Aircraft({
    required this.icao24,
    required this.callsign,
    required this.position,
    this.originCountry,
    this.altitudeMeters,
    this.velocityMps,
    this.headingDegrees,
    this.verticalRateMps,
    this.onGround = false,
  });

  double? get altitudeFeet => altitudeMeters == null ? null : altitudeMeters! * 3.28084;
  double? get speedKmh => velocityMps == null ? null : velocityMps! * 3.6;
  double? get speedKnots => velocityMps == null ? null : velocityMps! * 1.94384;

  /// OpenSky returns each state vector as a positional array.
  static Aircraft? fromOpenSkyState(List<dynamic> s) {
    final lon = (s.length > 5 ? s[5] : null) as num?;
    final lat = (s.length > 6 ? s[6] : null) as num?;
    if (lat == null || lon == null) return null;
    return Aircraft(
      icao24: (s[0] ?? '').toString().trim(),
      callsign: (s.length > 1 ? s[1] : '')?.toString().trim() ?? '',
      originCountry: s.length > 2 ? s[2]?.toString() : null,
      position: LatLng(lat.toDouble(), lon.toDouble()),
      onGround: s.length > 8 ? (s[8] == true) : false,
      velocityMps: (s.length > 9 ? s[9] : null) as double?,
      headingDegrees: (s.length > 10 ? s[10] : null) as double?,
      verticalRateMps: (s.length > 11 ? s[11] : null) as double?,
      altitudeMeters: (s.length > 13 ? s[13] : (s.length > 7 ? s[7] : null)) as double?,
    );
  }
}
