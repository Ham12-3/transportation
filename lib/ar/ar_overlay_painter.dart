import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Paints a ground-anchored AR route ribbon: a perspective "carpet" that lies on
/// the pavement, receding to a vanishing point at the horizon, with a soft glow,
/// bright edges, and filled chevrons flowing forward. The whole ribbon bends
/// toward the next turn and shifts with [relativeAngle] so it stays locked to
/// the real-world direction of travel. Modelled on live-view AR walking nav.
class ARPathPainter extends CustomPainter {
  ARPathPainter({
    required this.relativeAngle,
    required this.turn,
    this.pulse = 0,
  });

  /// -180..180. 0 = the route continues straight ahead; +ve = bears right.
  final double relativeAngle;
  final String turn; // LEFT / RIGHT / STRAIGHT / ARRIVE
  final double pulse; // 0..1 animation phase

  // Quadratic bezier point.
  Offset _bezier(Offset p0, Offset p1, Offset p2, double t) {
    final u = 1 - t;
    return Offset(
      u * u * p0.dx + 2 * u * t * p1.dx + t * t * p2.dx,
      u * u * p0.dy + 2 * u * t * p1.dy + t * t * p2.dy,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // Horizon (where the path vanishes) and the near edge at the user's feet.
    final horizonY = h * 0.50;
    final baseY = h * 1.04;
    final midY = (baseY + horizonY) / 2;

    // Shift + bend the vanishing point toward the upcoming turn.
    final shift = (relativeAngle / 40).clamp(-1.3, 1.3) * (w * 0.24);
    final vpX = w / 2 + shift;
    final bendX = w / 2 + shift * 0.55;

    final baseHalf = w * 0.30; // half-width at the feet
    final farHalf = w * 0.028; // half-width at the horizon

    // Centre-line control points (near -> mid -> far).
    final cNear = Offset(w / 2, baseY);
    final cCtrl = Offset(bendX, midY);
    final cFar = Offset(vpX, horizonY);

    // Build the ribbon by walking the centre line and offsetting by the
    // perspective-scaled half-width at each depth.
    const steps = 24;
    final left = <Offset>[];
    final right = <Offset>[];
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final c = _bezier(cNear, cCtrl, cFar, t);
      final half = _lerp(baseHalf, farHalf, t);
      left.add(Offset(c.dx - half, c.dy));
      right.add(Offset(c.dx + half, c.dy));
    }
    final ribbon = Path()..moveTo(left.first.dx, left.first.dy);
    for (final p in left.skip(1)) {
      ribbon.lineTo(p.dx, p.dy);
    }
    for (final p in right.reversed) {
      ribbon.lineTo(p.dx, p.dy);
    }
    ribbon.close();

    // 1) Soft outer glow so the ribbon feels lit, not pasted.
    canvas.drawPath(
      ribbon,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.40)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26),
    );

    // 2) Gradient fill — brighter and more opaque near the viewer.
    canvas.drawPath(
      ribbon,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            const Color(0xFF1A6FEB).withValues(alpha: 0.78),
            const Color(0xFF3D8BFF).withValues(alpha: 0.42),
            const Color(0xFF8FBEFF).withValues(alpha: 0.06),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromLTRB(0, horizonY, w, baseY)),
    );

    // 3) Bright edge highlights along both rails.
    final edgeL = Path()..moveTo(left.first.dx, left.first.dy);
    for (final p in left.skip(1)) {
      edgeL.lineTo(p.dx, p.dy);
    }
    final edgeR = Path()..moveTo(right.first.dx, right.first.dy);
    for (final p in right.skip(1)) {
      edgeR.lineTo(p.dx, p.dy);
    }
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.60)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    canvas.drawPath(edgeL, edgePaint);
    canvas.drawPath(edgeR, edgePaint);

    // 4) Contact glow where the ribbon meets the ground at the viewer's feet.
    canvas.drawCircle(
      Offset(w / 2, baseY),
      baseHalf * 1.1,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );

    // 5) Chevrons flowing forward along the ribbon (bunching toward horizon).
    const count = 6;
    for (var i = 0; i < count; i++) {
      final phase = ((i + pulse) % count) / count; // 0 (near) .. 1 (far)
      final t = math.pow(phase, 1.7).toDouble(); // perspective bunching
      final c = _bezier(cNear, cCtrl, cFar, t);
      final scale = 1 - t;
      if (scale <= 0.04) continue;
      final half = (_lerp(baseHalf, farHalf, t)) * 0.66;
      final rise = 30 * scale + 6;
      // Fade in as a chevron spawns at the feet, fade out toward the horizon.
      final spawn = phase < 0.08 ? phase / 0.08 : 1.0;
      final op = (0.92 * (1 - t) + 0.12).clamp(0.0, 1.0) * spawn;

      final chevron = Path()
        ..moveTo(c.dx - half, c.dy)
        ..lineTo(c.dx, c.dy - rise)
        ..lineTo(c.dx + half, c.dy);
      canvas.drawPath(
        chevron,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 16 * scale + 4
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: op),
      );
    }
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(covariant ARPathPainter old) =>
      old.relativeAngle != relativeAngle || old.turn != turn || old.pulse != pulse;
}

/// A floating destination marker anchored at the horizon and offset horizontally
/// by the real-world bearing, so it appears pinned to the destination direction.
class DestinationBearingBadge extends StatelessWidget {
  const DestinationBearingBadge({
    super.key,
    required this.relativeAngle,
    required this.label,
    this.title = 'Destination',
  });
  final double relativeAngle;
  final String label;
  final String title;

  @override
  Widget build(BuildContext context) {
    // Clamp so the marker stays on-screen even when the destination is behind.
    final dx = (relativeAngle / 70).clamp(-1.0, 1.0) * 130;
    final behind = relativeAngle.abs() > 90;
    return Transform.translate(
      offset: Offset(dx, 0),
      child: Opacity(
        opacity: behind ? 0.55 : 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.55),
                      blurRadius: 18,
                      offset: const Offset(0, 6)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.place_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: Color(0xFFCFE0FF),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4)),
                      Text(label,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ],
              ),
            ),
            // downward pointer
            Transform.translate(
              offset: const Offset(0, -2),
              child: Transform.rotate(
                angle: math.pi / 4,
                child: Container(width: 12, height: 12, color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
