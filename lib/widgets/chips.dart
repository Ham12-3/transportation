import 'package:flutter/material.dart';
import '../models/transport_mode.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'roundel.dart';

/// A line badge — a tube-map style pill carrying a line name or route number,
/// painted in that line's official colour.
class LineBadge extends StatelessWidget {
  const LineBadge(
    this.text, {
    super.key,
    this.background = AppColors.primary,
    this.foreground = Colors.white,
    this.pill = false,
  });

  final String text;
  final Color background;
  final Color foreground;
  final bool pill;

  /// Colour the badge by its real TfL line colour (Circle yellow, District
  /// green, bus red…), picking a legible foreground automatically.
  factory LineBadge.line(String text) {
    final bg = AppColors.lineColor(text);
    return LineBadge(text, background: bg, foreground: AppColors.onLine(bg));
  }

  factory LineBadge.free() => const LineBadge('FREE',
      background: AppColors.greenTint, foreground: AppColors.green);
  factory LineBadge.status(String s) => LineBadge(s,
      background: AppColors.greenTint, foreground: AppColors.green, pill: true);
  factory LineBadge.eta(String s) => LineBadge(s,
      background: AppColors.amberTint, foreground: AppColors.amberText, pill: true);

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: pill ? 12 : 8, vertical: pill ? 5 : 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: pill ? AppRadius.pill : AppRadius.badge,
        ),
        child: Text(text,
            style: TextStyle(
                color: foreground, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
      );
}

/// A mode filter tile in the Home grid — icon + label, selectable. Selected
/// tiles fill with the corporate blue and glow; the rest read as quiet cards.
class ModeChip extends StatelessWidget {
  const ModeChip({
    super.key,
    required this.mode,
    required this.selected,
    this.onTap,
  });

  final TransportMode mode;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg = selected ? AppColors.primary : Colors.white;
    final Color fg = selected ? Colors.white : AppColors.modeSlate;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.tile,
          border: selected ? null : Border.all(color: AppColors.hairline),
          boxShadow: selected ? AppShadows.blueGlow : AppShadows.card,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(mode.icon, size: 22, color: fg),
            const SizedBox(height: 5),
            Text(mode.label,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: fg)),
          ],
        ),
      ),
    );
  }
}

/// A small station marker built from the roundel — used in list rows in place
/// of a generic coloured circle.
class StopIndicator extends StatelessWidget {
  const StopIndicator(this.letter, {super.key, this.color = AppColors.roundelRed});
  final String letter;
  final Color color;
  @override
  Widget build(BuildContext context) => const Roundel(size: 26);
}
