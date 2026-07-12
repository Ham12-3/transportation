import 'package:flutter/material.dart';

/// The app's colour identity is Transport for London's own system — the
/// corporate blue, the roundel red, and the official Underground line colours.
/// Nothing here is a generic "product blue"; every value traces to real TfL
/// signage so the app reads as London, not as a template.
class AppColors {
  AppColors._();

  // ── Brand: the Underground corporate palette ──
  static const Color primary = Color(0xFF0019A8); // TfL Corporate Blue
  static const Color primaryPressed = Color(0xFF00126F);
  static const Color navy = Color(0xFF000E4D); // header ink-navy (deeper blue)
  static const Color blueTint = Color(0xFFE4E8F6); // tint of corporate blue

  // The roundel: a red ring crossed by a blue bar. Red doubles as the alert /
  // destination colour, matching London bus + Central-line red.
  static const Color roundelRed = Color(0xFFDC241F);
  static const Color roundelBlue = primary;

  // ── Semantic ──
  static const Color green = Color(0xFF007D32); // District-green "on time"
  static const Color greenTint = Color(0xFFE0F0E5);
  static const Color red = roundelRed;
  static const Color amber = Color(0xFFC46A00);
  static const Color amberTint = Color(0xFFFBEAC9);
  static const Color amberText = Color(0xFF8A4B00);

  // ── Neutrals ──
  static const Color ink = Color(0xFF10131A); // headlines
  static const Color text = Color(0xFF40464F); // body
  static const Color textStrong = Color(0xFF191E28);
  static const Color muted = Color(0xFF6B727C); // captions (AA on white)
  static const Color hairline = Color(0xFFE7EAEF);
  static const Color surface = Color(0xFFF2F3F6); // app background
  static const Color surfaceAlt = Color(0xFFE3E7EC); // map background
  static const Color white = Color(0xFFFFFFFF);
  static const Color road = Color(0xFFF2C14E);

  // Map decoration
  static const Color water = Color(0xFFAFD4EA);
  static const Color park = Color(0xFFCFE6C6);

  // ── Dark mode variant ──
  static const Color darkBg = Color(0xFF0A0F1E);
  static const Color darkCard = Color(0xFF141B2E);
  static const Color darkPrimary = Color(0xFF6E8BFF);
  static const Color darkGreen = Color(0xFF5EE08D);
  static const Color darkText = Color(0xFFE7EEF6);
  static const Color darkMuted = Color(0xFF9FB0C6);

  // Generic slate for non-line chips (bus numbers fall back to bus red below).
  static const Color modeSlate = Color(0xFF40464F);

  // Named lines kept for callers that reference them directly.
  static const Color hex = Color(0xFF532E63); // Heathrow Express
  static const Color elizabeth = Color(0xFF6950A1); // Elizabeth line
  static const Color gatwick = Color(0xFFEE2E24); // Gatwick Express

  // ── Official TfL line colours ──
  // Source: TfL colour standard. Used by [lineColor] to paint every badge in
  // its true colour instead of one flat blue.
  static const Map<String, Color> _line = {
    'bakerloo': Color(0xFFB36305),
    'central': Color(0xFFE32017),
    'circle': Color(0xFFFFD300),
    'district': Color(0xFF00782A),
    'hammersmith & city': Color(0xFFF3A9BB),
    'hammersmith and city': Color(0xFFF3A9BB),
    'jubilee': Color(0xFFA0A5A9),
    'metropolitan': Color(0xFF9B0056),
    'northern': Color(0xFF000000),
    'piccadilly': Color(0xFF003688),
    'victoria': Color(0xFF0098D4),
    'waterloo & city': Color(0xFF95CDBA),
    'waterloo and city': Color(0xFF95CDBA),
    'elizabeth': Color(0xFF6950A1),
    'dlr': Color(0xFF00A4A7),
    'docklands light railway': Color(0xFF00A4A7),
    'london overground': Color(0xFFEE7C0E),
    'overground': Color(0xFFEE7C0E),
    'liberty': Color(0xFF676767),
    'lioness': Color(0xFFFFA600),
    'mildmay': Color(0xFF0077AD),
    'suffragette': Color(0xFF18A95D),
    'weaver': Color(0xFF9B0058),
    'windrush': Color(0xFFDC241F),
    'tram': Color(0xFF66CC00),
    'tramlink': Color(0xFF66CC00),
    'thameslink': Color(0xFFE5308A),
    'heathrow express': Color(0xFF532E63),
    'gatwick express': Color(0xFFEE2E24),
  };

  /// London bus red — every numbered bus service shares it.
  static const Color busRed = Color(0xFFDC241F);

  /// The true colour for a line by its TfL name. Falls back to bus red for
  /// numeric bus routes and corporate blue for anything unrecognised.
  static Color lineColor(String? name) {
    if (name == null || name.trim().isEmpty) return primary;
    final key = name.trim().toLowerCase();
    final exact = _line[key];
    if (exact != null) return exact;
    // Partial match ("Circle and Hammersmith & City" etc.)
    for (final entry in _line.entries) {
      if (key.contains(entry.key)) return entry.value;
    }
    // Numeric route (bus / night bus like "N4") → bus red.
    if (RegExp(r'^[nN]?\d').hasMatch(key)) return busRed;
    return primary;
  }

  /// Foreground colour that stays legible on a given line colour — dark ink on
  /// the pale lines (Circle yellow, Jubilee grey, H&C pink), white otherwise.
  static Color onLine(Color c) =>
      c.computeLuminance() > 0.55 ? ink : white;
}
