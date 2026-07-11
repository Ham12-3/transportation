import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Uppercase section header — "Nearest Stops", "Suggested"…
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.padding});
  final String text;
  final EdgeInsets? padding;
  @override
  Widget build(BuildContext context) => Padding(
        padding: padding ?? const EdgeInsets.only(bottom: 10),
        child: Text(text.toUpperCase(),
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                letterSpacing: 0.8)),
      );
}

/// A standard white rounded card with the soft design shadow.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(15),
    this.onTap,
    this.color,
    this.border,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final surface = color ??
        (Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkCard
            : Colors.white);
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.card,
        border: border,
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: AppRadius.card, onTap: onTap, child: content),
    );
  }
}

/// Rounded square icon holder used in list rows & headers (blue-tint bg).
class IconBadge extends StatelessWidget {
  const IconBadge(this.icon,
      {super.key, this.size = 34, this.background = AppColors.blueTint, this.color = AppColors.primary});
  final IconData icon;
  final double size;
  final Color background;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(size * 0.3)),
        child: Icon(icon, color: color, size: size * 0.58),
      );
}

/// Duration formatting: "22 min" with a smaller unit suffix.
class DurationText extends StatelessWidget {
  const DurationText(this.minutes,
      {super.key, this.size = 19, this.color = AppColors.textStrong});
  final int minutes;
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => RichText(
        text: TextSpan(children: [
          TextSpan(
              text: '$minutes',
              style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: color)),
          TextSpan(
              text: ' min',
              style: TextStyle(
                  fontSize: size * 0.58, fontWeight: FontWeight.w600, color: AppColors.muted)),
        ]),
      );
}
