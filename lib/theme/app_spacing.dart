import 'package:flutter/widgets.dart';

/// Spacing scale, corner radii and shared shadows lifted from the design.
class AppSpacing {
  AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;

  // Radii
  static const double rChip = 7;
  static const double rBadge = 6;
  static const double rCard = 16;
  static const double rField = 16;
  static const double rTile = 14;
  static const double rPill = 22;
  static const double rSheet = 26;
  static const double rPhone = 48;
}

class AppRadius {
  AppRadius._();
  static const BorderRadius card = BorderRadius.all(Radius.circular(AppSpacing.rCard));
  static const BorderRadius field = BorderRadius.all(Radius.circular(AppSpacing.rField));
  static const BorderRadius tile = BorderRadius.all(Radius.circular(AppSpacing.rTile));
  static const BorderRadius badge = BorderRadius.all(Radius.circular(AppSpacing.rBadge));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(AppSpacing.rPill));
  static const BorderRadius sheet =
      BorderRadius.vertical(top: Radius.circular(AppSpacing.rSheet));
}

class AppShadows {
  AppShadows._();

  /// Soft card shadow: 0 2px 8px rgba(20,27,38,.07)
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x12141B26), blurRadius: 8, offset: Offset(0, 2)),
  ];

  /// Elevated float: 0 6px 18px rgba(20,27,38,.18)
  static const List<BoxShadow> float = [
    BoxShadow(color: Color(0x2E141B26), blurRadius: 18, offset: Offset(0, 6)),
  ];

  /// Blue button glow: corporate blue at ~28% for selected/CTA lift.
  static const List<BoxShadow> blueGlow = [
    BoxShadow(color: Color(0x470019A8), blurRadius: 16, offset: Offset(0, 6)),
  ];

  /// Bottom sheet lift: 0 -12px 34px rgba(20,27,38,.18)
  static const List<BoxShadow> sheet = [
    BoxShadow(color: Color(0x2E141B26), blurRadius: 34, offset: Offset(0, -12)),
  ];
}

/// Small helper for the drag handle used on every bottom sheet.
class SheetGrabber extends StatelessWidget {
  const SheetGrabber({super.key, this.color});
  final Color? color;
  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        height: 5,
        decoration: BoxDecoration(
          color: color ?? const Color(0xFFD2D8DE),
          borderRadius: BorderRadius.circular(3),
        ),
      );
}
