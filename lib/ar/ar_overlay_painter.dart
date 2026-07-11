import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Paints the AR path: a perspective "carpet" plus a stack of floating
/// chevrons that shift horizontally with [relativeAngle] so the route appears
/// anchored to the real-world street ahead. Matches the S7 chevron overlay.
class ARPathPainter extends CustomPainter {
  ARPathPainter({
    required this.relativeAngle,
    required this.turn,
    this.pulse = 0,
  });

  /// -180..180. 0 = turn is straight ahead; positive = to the right.
  final double relativeAngle;
  final String turn; // LEFT / RIGHT / STRAIGHT
  final double pulse; // 0..1 animation phase

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // Clamp the horizontal offset so overlays stay on-screen even on sharp turns.
    final offset = (relativeAngle / 45).clamp(-1.0, 1.0) * (w * 0.28);
    final vanishX = w / 2 + offset;
    final vanishY = h * 0.46;
    final baseY = h * 0.98;
    final baseHalf = w * 0.20;
    final topHalf = w * 0.045;

    // Path carpet (gradient, semi-transparent blue).
    final carpet = Path()
      ..moveTo(w / 2 - baseHalf, baseY)
      ..lineTo(vanishX - topHalf, vanishY)
      ..lineTo(vanishX + topHalf, vanishY)
      ..lineTo(w / 2 + baseHalf, baseY)
      ..close();
    final carpetPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.62),
          const Color(0xFF4D93FF).withValues(alpha: 0.30),
        ],
      ).createShader(Rect.fromLTRB(0, vanishY, w, baseY));
    canvas.drawPath(carpet, carpetPaint);
    canvas.drawPath(
      carpet,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.blueTint.withValues(alpha: 0.5),
    );

    // Chevrons marching up the carpet toward the vanishing point.
    const count = 5;
    for (var i = 0; i < count; i++) {
      final tRaw = i / count + pulse * (1 / count);
      final t = tRaw % 1.0; // 0 (near) .. 1 (far)
      final y = baseY + (vanishY - baseY) * t;
      final cx = (w / 2) + (vanishX - w / 2) * t;
      final scale = 1 - t;
      final half = (baseHalf * 0.5) * scale + topHalf;
      final thick = (16 * scale + 5);
      final opacity = (0.95 - t * 0.35).clamp(0.0, 1.0);

      final chevron = Path()
        ..moveTo(cx - half, y)
        ..lineTo(cx, y - thick * 1.6)
        ..lineTo(cx + half, y);
      canvas.drawPath(
        chevron,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = thick
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: opacity),
      );
    }

    // Turn arrow near the vanishing point for LEFT/RIGHT turns.
    if (turn == 'LEFT' || turn == 'RIGHT') {
      _drawTurnArrow(canvas, Offset(vanishX, vanishY - 26), turn == 'RIGHT');
    }
  }

  void _drawTurnArrow(Canvas canvas, Offset c, bool right) {
    final dir = right ? 1 : -1;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(c.dx - 22 * dir, c.dy + 14)
      ..lineTo(c.dx - 22 * dir, c.dy)
      ..quadraticBezierTo(c.dx - 22 * dir, c.dy - 14, c.dx - 8 * dir, c.dy - 14)
      ..lineTo(c.dx + 14 * dir, c.dy - 14);
    canvas.drawPath(path, paint);
    // arrow head
    final head = Path()
      ..moveTo(c.dx + 6 * dir, c.dy - 24)
      ..lineTo(c.dx + 20 * dir, c.dy - 14)
      ..lineTo(c.dx + 6 * dir, c.dy - 4);
    canvas.drawPath(head, paint);
  }

  @override
  bool shouldRepaint(covariant ARPathPainter old) =>
      old.relativeAngle != relativeAngle || old.turn != turn || old.pulse != pulse;
}

/// A compass ring showing where the destination sits relative to device heading.
class DestinationBearingBadge extends StatelessWidget {
  const DestinationBearingBadge({super.key, required this.relativeAngle, required this.label});
  final double relativeAngle;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset((relativeAngle / 90).clamp(-1.0, 1.0) * 120, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.rotate(
            angle: relativeAngle * math.pi / 180,
            child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
            child: Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
