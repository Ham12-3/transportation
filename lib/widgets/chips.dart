import 'package:flutter/material.dart';
import '../models/transport_mode.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The coloured line/mode badge — "CMX1", "4", "381", "FREE", "in 5 min".
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

  factory LineBadge.free() => const LineBadge('FREE',
      background: AppColors.greenTint, foreground: AppColors.green);
  factory LineBadge.status(String s) => LineBadge(s,
      background: AppColors.greenTint, foreground: AppColors.green, pill: true);
  factory LineBadge.eta(String s) => LineBadge(s,
      background: AppColors.amberTint, foreground: AppColors.amberText, pill: true);

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: pill ? 12 : 7, vertical: pill ? 5 : 3),
        decoration: BoxDecoration(
          color: background,
          borderRadius: pill ? AppRadius.pill : AppRadius.badge,
        ),
        child: Text(text,
            style: TextStyle(
                color: foreground, fontSize: pill ? 12 : 12, fontWeight: FontWeight.w800)),
      );
}

/// A mode filter tile in the Home grid (icon + label, selectable).
class ModeChip extends StatelessWidget {
  const ModeChip({
    super.key,
    required this.mode,
    required this.selected,
    this.onTap,
    this.isAll = false,
  });

  final TransportMode mode;
  final bool selected;
  final VoidCallback? onTap;
  final bool isAll;

  @override
  Widget build(BuildContext context) {
    final Color bg = isAll
        ? (selected ? AppColors.primary : AppColors.textStrong)
        : (selected ? AppColors.primary : Colors.white);
    final Color fg = (selected || isAll) ? Colors.white : AppColors.modeSlate;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.tile,
          boxShadow: selected ? AppShadows.blueGlow : AppShadows.card,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(mode.icon, size: 22, color: fg),
            const SizedBox(height: 4),
            Text(mode.label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: fg)),
          ],
        ),
      ),
    );
  }
}

/// Small circular avatar badge (e.g. the red "D" stop indicator).
class StopIndicator extends StatelessWidget {
  const StopIndicator(this.letter, {super.key, this.color = AppColors.red});
  final String letter;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Text(letter,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
      );
}
