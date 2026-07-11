import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// The transit modes surfaced as filter chips on the Home screen.
enum TransportMode {
  all('all', 'All'),
  bus('bus', 'Bus'),
  tube('tube', 'Tube'),
  rail('national-rail', 'Rail'),
  tram('tram', 'Tram'),
  ferry('river-bus', 'Ferry'),
  cycle('cycle', 'Cycle'),
  walking('walking', 'Walk'),
  air('air', 'Air'),
  saved('saved', 'Saved');

  const TransportMode(this.tflId, this.label);

  /// The identifier TfL's Journey Planner expects in the `mode` param.
  final String tflId;
  final String label;

  /// Colour used for the line/mode badge chip.
  Color get chipColor {
    switch (this) {
      case TransportMode.tube:
      case TransportMode.air:
        return AppColors.primary;
      default:
        return AppColors.modeSlate;
    }
  }

  IconData get icon {
    switch (this) {
      case TransportMode.bus:
        return Icons.directions_bus_rounded;
      case TransportMode.tube:
        return Icons.subway_rounded;
      case TransportMode.rail:
        return Icons.train_rounded;
      case TransportMode.tram:
        return Icons.tram_rounded;
      case TransportMode.ferry:
        return Icons.directions_boat_rounded;
      case TransportMode.cycle:
        return Icons.directions_bike_rounded;
      case TransportMode.walking:
        return Icons.directions_walk_rounded;
      case TransportMode.air:
        return Icons.flight_rounded;
      case TransportMode.saved:
        return Icons.star_rounded;
      case TransportMode.all:
        return Icons.more_horiz_rounded;
    }
  }

  static TransportMode fromTfl(String? id) {
    if (id == null) return TransportMode.bus;
    final v = id.toLowerCase();
    return TransportMode.values.firstWhere(
      (m) => m.tflId == v || m.name == v,
      orElse: () {
        if (v.contains('bus')) return TransportMode.bus;
        if (v.contains('tube') || v.contains('underground')) return TransportMode.tube;
        if (v.contains('rail') || v.contains('overground') || v.contains('elizabeth')) {
          return TransportMode.rail;
        }
        if (v.contains('tram')) return TransportMode.tram;
        if (v.contains('walk')) return TransportMode.walking;
        if (v.contains('cycle')) return TransportMode.cycle;
        return TransportMode.bus;
      },
    );
  }
}
