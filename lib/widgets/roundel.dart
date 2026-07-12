import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';

/// The Underground roundel — the app's signature mark.
///
/// A red ring crossed by a horizontal bar. With no [label] it is a pure brand
/// mark (headers, markers); with a [label] the bar carries a line or station
/// name, exactly like the real thing on a platform.
class Roundel extends StatelessWidget {
  const Roundel({
    super.key,
    this.size = 28,
    this.ringColor = AppColors.roundelRed,
    this.barColor = AppColors.roundelBlue,
    this.label,
    this.labelColor,
  });

  final double size;
  final Color ringColor;
  final Color barColor;
  final String? label;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final barHeight = label == null ? size * 0.30 : size * 0.40;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Red ring
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ringColor, width: size * 0.135),
            ),
          ),
          // Blue bar (extends just past the ring, like TfL signage)
          Container(
            width: size * 1.06,
            height: barHeight,
            alignment: Alignment.center,
            color: barColor,
            child: label == null
                ? null
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: size * 0.08),
                      child: Text(
                        label!,
                        maxLines: 1,
                        style: TextStyle(
                          color: labelColor ?? Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: size * 0.30,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// The app's on-brand loading indicator — a complete roundel that gently
/// breathes (scale + fade), so it always reads as the mark rather than a
/// spinner with a chunk missing.
class RoundelLoader extends StatelessWidget {
  const RoundelLoader({
    super.key,
    this.size = 40,
    this.ringColor = AppColors.roundelRed,
    this.barColor = AppColors.roundelBlue,
  });
  final double size;
  final Color ringColor;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    return Roundel(size: size, ringColor: ringColor, barColor: barColor)
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 0.82, end: 1.0, duration: 720.ms, curve: Curves.easeInOut)
        .fadeIn(begin: 0.55, duration: 720.ms);
  }
}

/// The horizontal "brand lockup": a roundel next to a wordmark. Used in headers.
class RoundelWordmark extends StatelessWidget {
  const RoundelWordmark({
    super.key,
    required this.text,
    this.color = Colors.white,
    this.size = 26,
    this.ringColor = AppColors.roundelRed,
    this.barColor = Colors.white,
  });

  final String text;
  final Color color;
  final double size;
  final Color ringColor;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Roundel(size: size, ringColor: ringColor, barColor: barColor),
        SizedBox(width: size * 0.42),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: size * 0.78,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
