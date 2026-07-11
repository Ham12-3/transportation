import 'package:flutter/material.dart';
import '../models/arrival.dart';
import '../models/stop_point.dart';
import '../theme/app_colors.dart';
import 'chips.dart';

/// A nearest-stop row: coloured indicator, name + walk time, trailing action.
class StopRow extends StatelessWidget {
  const StopRow({super.key, required this.stop, this.onTap, this.leadingLetter});
  final StopPoint stop;
  final VoidCallback? onTap;
  final String? leadingLetter;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          child: Row(
            children: [
              StopIndicator(leadingLetter ?? _letter(stop.name)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stop.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textStrong)),
                    const SizedBox(height: 1),
                    Text('${stop.walkMinutes} min walk',
                        style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFC6CDD5)),
            ],
          ),
        ),
      );

  String _letter(String s) => s.isEmpty ? '•' : s[0].toUpperCase();
}

/// A live-arrival row: line badge, destination, ETA (green if imminent).
class ArrivalRow extends StatelessWidget {
  const ArrivalRow({super.key, required this.arrival});
  final Arrival arrival;
  @override
  Widget build(BuildContext context) {
    final imminent = arrival.minutes <= 2;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      child: Row(
        children: [
          LineBadge(arrival.lineName, background: arrival.mode.chipColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text('to ${arrival.destinationName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
          ),
          Text(arrival.etaLabel,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: imminent ? AppColors.green : AppColors.textStrong)),
        ],
      ),
    );
  }
}
