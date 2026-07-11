import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Primary filled blue button — "Start journey" in the style guide.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 8)],
        Text(label,
            style: const TextStyle(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
      ],
    );
    return Material(
      color: AppColors.primary,
      borderRadius: AppRadius.field,
      elevation: 0,
      child: InkWell(
        borderRadius: AppRadius.field,
        onTap: onPressed,
        child: Ink(
          decoration: const BoxDecoration(
            borderRadius: AppRadius.field,
            boxShadow: AppShadows.blueGlow,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Secondary blue-tint button.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, this.onPressed, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.blueTint,
        borderRadius: AppRadius.field,
        child: InkWell(
          borderRadius: AppRadius.field,
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8)
                ],
                Text(label,
                    style: const TextStyle(
                        color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      );
}

/// The circular blue GO button from the Route Detail map.
class GoButton extends StatelessWidget {
  const GoButton({super.key, this.onPressed, this.size = 78, this.label = 'GO'});
  final VoidCallback? onPressed;
  final double size;
  final String label;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onPressed,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x801A6FEB), blurRadius: 26, offset: Offset(0, 10)),
            ],
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5)),
        ),
      );
}

/// A floating circular icon button (map controls, AR controls).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.background = Colors.white,
    this.iconColor = AppColors.primary,
    this.size = 48,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color background;
  final Color iconColor;
  final double size;

  @override
  Widget build(BuildContext context) => Material(
        color: background,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
              boxShadow: AppShadows.float,
            ),
            child: Icon(icon, color: iconColor, size: size * 0.46),
          ),
        ),
      );
}
