import 'package:flutter/material.dart';
import '../models/journey.dart';
import '../models/transport_mode.dart';
import '../theme/app_colors.dart';
import 'chips.dart';
import 'common.dart';

/// A route option card in the Results list — line badges, live departures,
/// price and duration. Matches the S2 "Suggested" cards.
class RouteCard extends StatelessWidget {
  const RouteCard({super.key, required this.journey, this.onTap, this.liveNote});
  final Journey journey;
  final VoidCallback? onTap;
  final String? liveNote;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...journey.lineBadges.take(4).map((b) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: LineBadge(b, background: _badgeColor(b, journey)),
                  )),
              const Spacer(),
              if (journey.fareLabel != null && journey.fareLabel != 'FREE')
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Text(journey.fareLabel!,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
                ),
              if (journey.fareLabel == 'FREE')
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: LineBadge.free(),
                ),
              DurationText(journey.durationMinutes),
            ],
          ),
          if (liveNote != null) ...[
            const SizedBox(height: 8),
            Text(liveNote!,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.green, fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }

  Color _badgeColor(String badge, Journey j) {
    // Tube/rail line legs render blue; buses render slate — mirror the design.
    final leg = j.legs.firstWhere(
      (l) => (l.lineName ?? l.mode.label) == badge,
      orElse: () => j.legs.first,
    );
    return leg.mode == TransportMode.tube || leg.mode == TransportMode.tram
        ? AppColors.primary
        : AppColors.modeSlate;
  }
}
