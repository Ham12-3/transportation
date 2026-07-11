import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/journey.dart';
import '../models/transport_mode.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/common.dart';
import '../widgets/route_card.dart';
import '../widgets/state_views.dart';

/// Walking + cycling comparison journeys for the summary chips.
final _compareProvider = FutureProvider.autoDispose<Map<TransportMode, Journey?>>((ref) async {
  final q = ref.watch(searchProvider);
  if (!q.isReady) return {};
  final tfl = ref.read(tflServiceProvider);
  String from = q.from;
  if (from == 'Current Location') {
    final loc = await ref.read(currentLocationProvider.future);
    from = '${loc.latitude},${loc.longitude}';
  }
  Future<Journey?> one(TransportMode m) async {
    try {
      final r = await tfl.planJourney(from: from, to: q.to, modes: [m]);
      return r.isEmpty ? null : r.first;
    } catch (_) {
      return null;
    }
  }

  final results = await Future.wait([one(TransportMode.walking), one(TransportMode.cycle)]);
  return {TransportMode.walking: results[0], TransportMode.cycle: results[1]};
});

/// S2 — Route Options / Results.
class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchProvider);
    final journeys = ref.watch(journeyProvider);
    final compare = ref.watch(_compareProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _Header(
            from: query.fromLabel,
            to: query.toLabel,
            whenLabel: query.when == null ? 'Now' : DateFormat('HH:mm').format(query.when!),
            onBack: () => context.pop(),
            onPickTime: () => _pickTime(context, ref),
          ),
          Expanded(
            child: journeys.when(
              loading: () => const LoadingView(label: 'Planning your journey…'),
              error: (e, _) => ErrorView(
                message: 'Journey planning failed. Check your destination and try again.',
                onRetry: () => ref.invalidate(journeyProvider),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const MessageView(
                    icon: Icons.route_rounded,
                    title: 'No routes found',
                    message: 'Try a different destination, time, or transport mode.',
                  );
                }
                final fastest =
                    list.map((j) => j.durationMinutes).reduce((a, b) => a < b ? a : b);
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                  children: [
                    _SummaryChips(compare: compare, transitMinutes: fastest),
                    const SizedBox(height: 20),
                    const SectionLabel('Suggested'),
                    ...list.asMap().entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: RouteCard(
                            journey: e.value,
                            liveNote: _liveNote(e.value),
                            onTap: () => context.push('/detail', extra: e.value),
                          ),
                        ).animate().fadeIn(delay: (e.key * 60).ms).slideY(begin: 0.08)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String? _liveNote(Journey j) {
    final ride = j.legs.firstWhere((l) => l.mode != TransportMode.walking,
        orElse: () => j.legs.first);
    if (ride.departurePoint.isEmpty) return null;
    return 'departs from ${ride.departurePoint}';
  }

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final picked = await showModalBottomSheet<DateTime?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _TimePickerSheet(initial: ref.read(searchProvider).when ?? now),
    );
    if (picked != null) {
      // A null DateTime inside the sheet means "Depart now".
      ref.read(searchProvider.notifier).setWhen(
            picked.isBefore(now.subtract(const Duration(minutes: 1))) ? null : picked,
          );
      ref.invalidate(journeyProvider);
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.from,
    required this.to,
    required this.whenLabel,
    required this.onBack,
    required this.onPickTime,
  });
  final String from, to, whenLabel;
  final VoidCallback onBack, onPickTime;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, top + 8, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.navy,
        boxShadow: [BoxShadow(color: Color(0x40173B6E), blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onPickTime,
                child: Row(children: [
                  Text(whenLabel,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _endpoint('START', from, const Color(0xFF5BA0FF), circle: true, rounded: true),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.14)),
          _endpoint('END', to, AppColors.red, circle: false),
        ],
      ),
    );
  }

  Widget _endpoint(String label, String value, Color dotColor,
      {bool circle = true, bool rounded = false}) {
    return Container(
      color: Colors.white.withValues(alpha: 0.10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: dotColor,
                shape: circle ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: circle ? null : BorderRadius.circular(2)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF9FBBDF), fontWeight: FontWeight.w600, letterSpacing: 0.4)),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChips extends StatelessWidget {
  const _SummaryChips({required this.compare, required this.transitMinutes});
  final AsyncValue<Map<TransportMode, Journey?>> compare;
  final int transitMinutes;

  @override
  Widget build(BuildContext context) {
    final data = compare.asData?.value ?? const {};
    final walk = data[TransportMode.walking];
    final cycle = data[TransportMode.cycle];
    return Row(
      children: [
        Expanded(
          child: _chip(
            icon: Icons.directions_walk_rounded,
            minutes: walk?.durationMinutes,
            sub: walk == null ? null : '${walk.durationMinutes * 4} cal',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _chip(
            icon: Icons.directions_bike_rounded,
            minutes: cycle?.durationMinutes,
            sub: cycle == null ? null : '${(cycle.durationMinutes * 8)} cal',
            prefix: '~',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _chip(
            icon: Icons.directions_transit_filled_rounded,
            minutes: transitMinutes,
            sub: 'Fastest',
            highlighted: true,
          ),
        ),
      ],
    );
  }

  Widget _chip({
    required IconData icon,
    required int? minutes,
    String? sub,
    bool highlighted = false,
    String prefix = '',
  }) {
    final color = highlighted ? AppColors.primary : AppColors.textStrong;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.blueTint : Colors.white,
        borderRadius: AppRadius.tile,
        border: highlighted ? Border.all(color: AppColors.primary, width: 1.5) : null,
        boxShadow: highlighted ? null : AppShadows.card,
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: highlighted ? AppColors.primary : AppColors.modeSlate),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                  text: minutes == null ? '—' : '$prefix$minutes',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: color)),
              if (minutes != null)
                const TextSpan(
                    text: ' min',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted)),
            ]),
          ),
          const SizedBox(height: 3),
          Text(sub ?? '',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: highlighted ? const Color(0xFF7FA9E6) : AppColors.muted)),
        ],
      ),
    );
  }
}

class _TimePickerSheet extends StatefulWidget {
  const _TimePickerSheet({required this.initial});
  final DateTime initial;
  @override
  State<_TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<_TimePickerSheet> {
  late DateTime _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
      decoration: const BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.sheet),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetGrabber(),
          const SizedBox(height: 16),
          const SectionLabel('Depart at'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DateFormat('EEE, HH:mm').format(_value),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () async {
                  final t = await showTimePicker(
                      context: context, initialTime: TimeOfDay.fromDateTime(_value));
                  if (t != null) {
                    setState(() => _value = DateTime(
                        _value.year, _value.month, _value.day, t.hour, t.minute));
                  }
                },
                child: const Text('Change'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, DateTime.now().subtract(const Duration(hours: 1))),
                  child: const Text('Depart now'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () => Navigator.pop(context, _value),
                  child: const Text('Set time'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
