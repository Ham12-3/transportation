import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// Material 3 theme built on the TfL corporate blue and a Johnston-inspired
/// type system: Hammersmith One (a face modelled on the Underground's Johnston
/// lettering) for signage-style display, Cabin for readable UI text.
class AppTheme {
  AppTheme._();

  static TextTheme _textTheme(TextTheme base, Color ink, Color body) {
    final cabin = GoogleFonts.cabinTextTheme(base);
    // The signage face — used only where the Underground personality should show.
    TextStyle display(double s, {double spacing = -0.3, Color? c}) =>
        GoogleFonts.hammersmithOne(
            fontSize: s, height: 1.05, letterSpacing: spacing, color: c ?? ink);

    return cabin.copyWith(
      displaySmall: display(30),
      headlineMedium: display(26),
      headlineSmall: display(22),
      titleLarge: display(20, spacing: -0.2),
      titleMedium: cabin.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: ink),
      titleSmall: cabin.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: body),
      bodyLarge: cabin.bodyLarge?.copyWith(fontWeight: FontWeight.w500, color: body),
      bodyMedium: cabin.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: body),
      labelLarge: cabin.labelLarge?.copyWith(fontWeight: FontWeight.w700, color: ink),
      labelSmall: cabin.labelSmall
          ?.copyWith(fontWeight: FontWeight.w600, color: AppColors.muted, letterSpacing: 0.6),
    );
  }

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      surface: AppColors.white,
      surfaceContainerLowest: AppColors.surface,
      onSurface: AppColors.textStrong,
      secondary: AppColors.roundelRed,
      error: AppColors.red,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.surface,
      textTheme: _textTheme(ThemeData.light().textTheme, AppColors.ink, AppColors.text),
      splashFactory: InkSparkle.splashFactory,
      dividerColor: AppColors.hairline,
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.darkPrimary,
      brightness: Brightness.dark,
    ).copyWith(
      surface: AppColors.darkCard,
      surfaceContainerLowest: AppColors.darkBg,
      onSurface: AppColors.darkText,
      secondary: AppColors.roundelRed,
      error: AppColors.red,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.darkBg,
      textTheme:
          _textTheme(ThemeData.dark().textTheme, AppColors.darkText, AppColors.darkMuted),
      dividerColor: const Color(0xFF223349),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      ),
    );
  }
}

/// Semantic text styles used across widgets. Signage face for numbers, Cabin
/// for the small utility labels.
extension AppTextStyles on BuildContext {
  TextStyle get bigNumber =>
      GoogleFonts.hammersmithOne(fontSize: 30, color: AppColors.ink, letterSpacing: -0.5);
  TextStyle get sectionLabel => GoogleFonts.cabin(
      fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.muted, letterSpacing: 1.2);
  TextStyle get rowTitle => GoogleFonts.cabin(
      fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textStrong);
  TextStyle get caption =>
      GoogleFonts.cabin(fontWeight: FontWeight.w500, fontSize: 12, color: AppColors.muted);
}
