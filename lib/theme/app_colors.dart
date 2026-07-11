import 'package:flutter/material.dart';

/// Central colour palette — the blue identity system from the design's
/// "Component & Colour Style Guide". Every colour in the app comes from here.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF1A6FEB); // Primary Blue
  static const Color primaryPressed = Color(0xFF0F52C9); // Blue Pressed
  static const Color navy = Color(0xFF173B6E); // Deep Navy
  static const Color blueTint = Color(0xFFEAF2FE); // Blue Tint

  // Semantic
  static const Color green = Color(0xFF1A9A55); // Live Green
  static const Color greenTint = Color(0xFFE4F6EC);
  static const Color red = Color(0xFFE23B3B); // Alert Red
  static const Color amber = Color(0xFFE38A1F);
  static const Color amberTint = Color(0xFFFBEFC4);
  static const Color amberText = Color(0xFF9A7B10);

  // Neutrals
  static const Color ink = Color(0xFF141B26); // Ink
  static const Color text = Color(0xFF33414F); // Text
  static const Color textStrong = Color(0xFF1A2330);
  static const Color muted = Color(0xFF8A94A1); // Muted
  static const Color hairline = Color(0xFFEDF0F3);
  static const Color surface = Color(0xFFF5F7F9); // Surface
  static const Color surfaceAlt = Color(0xFFE7EBEE); // Map bg
  static const Color white = Color(0xFFFFFFFF);
  static const Color road = Color(0xFFF2C14E); // Road yellow

  // Map decoration
  static const Color water = Color(0xFFAFD4EA);
  static const Color park = Color(0xFFCFE6C6);

  // Dark mode variant
  static const Color darkBg = Color(0xFF0E1826);
  static const Color darkCard = Color(0xFF16233A);
  static const Color darkPrimary = Color(0xFF4D93FF);
  static const Color darkGreen = Color(0xFF5EE08D);
  static const Color darkText = Color(0xFFE7EEF6);
  static const Color darkMuted = Color(0xFF9FB0C6);

  // Line-mode brand colours (for line/mode chips)
  static const Color modeSlate = Color(0xFF33414F); // bus/generic dark chip
  static const Color hex = Color(0xFF5B2D8E); // Heathrow Express
  static const Color elizabeth = Color(0xFF7A56C9);
  static const Color gatwick = Color(0xFFC0392B);
}
