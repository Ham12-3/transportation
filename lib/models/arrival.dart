import 'transport_mode.dart';

/// A live arrival prediction for a StopPoint (TfL /Arrivals).
class Arrival {
  final String id;
  final String lineName;
  final String destinationName;
  final int timeToStationSeconds;
  final TransportMode mode;
  final String? platformName;

  const Arrival({
    required this.id,
    required this.lineName,
    required this.destinationName,
    required this.timeToStationSeconds,
    required this.mode,
    this.platformName,
  });

  int get minutes => (timeToStationSeconds / 60).round();

  /// "Due" / "1 min" / "7 min" label.
  String get etaLabel => minutes <= 0 ? 'Due' : '$minutes min';

  factory Arrival.fromJson(Map<String, dynamic> j) => Arrival(
        id: (j['id'] ?? '').toString(),
        lineName: (j['lineName'] ?? j['lineId'] ?? '').toString(),
        destinationName:
            (j['destinationName'] ?? j['towards'] ?? 'Destination').toString(),
        timeToStationSeconds: (j['timeToStation'] as num?)?.toInt() ?? 0,
        mode: TransportMode.fromTfl(j['modeName']?.toString()),
        platformName: j['platformName']?.toString(),
      );
}
