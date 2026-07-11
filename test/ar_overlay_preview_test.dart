import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tube_london/ar/ar_overlay_painter.dart';

/// Renders the AR overlay over a simulated street scene to a PNG
/// (test/goldens/ar_overlay.png) so the overlay design can be reviewed without
/// a device. Run: flutter test --update-goldens test/ar_overlay_preview_test.dart
void main() {
  testWidgets('AR overlay preview', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(size: Size(390, 844)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: _ArScene(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(
      find.byType(_ArScene),
      matchesGoldenFile('goldens/ar_overlay.png'),
    );
  });
}

/// A simulated street background (so the AR ribbon is shown in context) plus the
/// real ARPathPainter + destination marker.
class _ArScene extends StatelessWidget {
  const _ArScene();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 390,
      height: 844,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Sky + buildings + road, roughly a street view.
          CustomPaint(painter: _StreetPainter()),
          // Depth scrim (same as the live screen).
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x66000000), Color(0x00000000), Color(0x00000000), Color(0x59000000)],
                stops: [0.0, 0.28, 0.68, 1.0],
              ),
            ),
          ),
          CustomPaint(
            painter: ARPathPainter(relativeAngle: 14, turn: 'RIGHT', pulse: 0.35),
          ),
        ],
      ),
    );
  }
}

class _StreetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, horizon = h * 0.5;
    // Sky
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, horizon),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFAAC4DA), Color(0xFFD8E2EA)],
        ).createShader(Rect.fromLTWH(0, 0, w, horizon)),
    );
    // Ground / road
    canvas.drawRect(
      Rect.fromLTWH(0, horizon, w, h - horizon),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9AA0A6), Color(0xFF676D73)],
        ).createShader(Rect.fromLTWH(0, horizon, w, h - horizon)),
    );
    // A skyline strip of buildings sitting on the horizon (left & right, with a
    // gap in the middle for the street to recede into).
    final bldg = Paint()..color = const Color(0xFF788592);
    final heights = [46.0, 70.0, 54.0, 90.0, 40.0, 64.0];
    var x = 0.0;
    for (var i = 0; i < heights.length && x < w * 0.34; i++) {
      final bw = 26.0 + (i.isEven ? 12 : 0);
      canvas.drawRect(Rect.fromLTWH(x, horizon - heights[i], bw, heights[i]), bldg);
      canvas.drawRect(Rect.fromLTWH(w - x - bw, horizon - heights[i], bw, heights[i]), bldg);
      x += bw + 6;
    }
    // Horizon line.
    canvas.drawRect(Rect.fromLTWH(0, horizon - 1.5, w, 2), Paint()..color = const Color(0xFF5B646E));
    // Faint perspective road edges converging at the vanishing point.
    final road = Paint()
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = 3;
    canvas.drawLine(Offset(w * 0.06, h), Offset(w * 0.5, horizon), road);
    canvas.drawLine(Offset(w * 0.94, h), Offset(w * 0.5, horizon), road);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
