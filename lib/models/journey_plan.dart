import 'journey.dart';
import 'transport_mode.dart';

/// Which endpoint TfL couldn't resolve uniquely.
enum AmbiguousEnd { destination, origin }

/// One candidate location offered by TfL when an endpoint is ambiguous
/// (the "Did you mean?" options).
class PlaceOption {
  final String name;
  final String? description;
  final double lat;
  final double lon;
  final List<TransportMode> modes;
  final int matchQuality;

  const PlaceOption({
    required this.name,
    required this.lat,
    required this.lon,
    this.description,
    this.modes = const [],
    this.matchQuality = 0,
  });

  /// "lat,lon" — what we feed back to the Journey Planner (never disambiguates).
  String get coord => '$lat,$lon';

  factory PlaceOption.fromTflOption(Map option) {
    final place = (option['place'] as Map?) ?? const {};
    return PlaceOption(
      name: (place['commonName'] ?? option['parameterValue'] ?? 'Location').toString(),
      description: place['placeType']?.toString(),
      lat: (place['lat'] as num?)?.toDouble() ?? 0,
      lon: (place['lon'] as num?)?.toDouble() ?? 0,
      modes: [
        for (final m in (place['modes'] as List? ?? const []))
          TransportMode.fromTfl(m.toString())
      ],
      matchQuality: (option['matchQuality'] as num?)?.toInt() ?? 0,
    );
  }

  bool get hasCoord => lat != 0 && lon != 0;
}

/// The outcome of a journey plan: either ranked journeys, or — when an endpoint
/// was ambiguous — the list of candidate locations to choose from.
class JourneyPlanResult {
  final List<Journey> journeys;
  final List<PlaceOption> options;
  final AmbiguousEnd? ambiguousEnd;

  const JourneyPlanResult({
    this.journeys = const [],
    this.options = const [],
    this.ambiguousEnd,
  });

  bool get hasJourneys => journeys.isNotEmpty;

  /// True when TfL returned multiple candidate locations instead of journeys.
  bool get needsChoice => journeys.isEmpty && options.isNotEmpty;
}
