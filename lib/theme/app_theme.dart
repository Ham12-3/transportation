import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// Material 3 theme seeded from the primary blue (#1A6FEB), plus the
/// Plus Jakarta Sans type ramp from the style guide. Whole app themes from here.
class AppTheme {
  AppTheme._();

  static TextTheme _textTheme(TextTheme base, Color ink, Color body) {
    final jakarta = GoogleFonts.plusJakartaSansTextTheme(base);
    return jakarta.copyWith(
      displaySmall: jakarta.displaySmall?.copyWith(
          fontWeight: FontWeight.w800, color: ink, letterSpacing: -0.5),
      headlineMedium: jakarta.headlineMedium
          ?.copyWith(fontWeight: FontWeight.w800, color: ink, letterSpacing: -0.5),
      headlineSmall: jakarta.headlineSmall
          ?.copyWith(fontWeight: FontWeight.w800, color: ink, letterSpacing: -0.5),
      titleLarge:
          jakarta.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: ink),
      titleMedium:
          jakarta.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: ink),
      titleSmall:
          jakarta.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: body),
      bodyLarge: jakarta.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: body),
      bodyMedium: jakarta.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: body),
      labelLarge:
          jakarta.labelLarge?.copyWith(fontWeight: FontWeight.w800, color: ink),
      labelSmall: jakarta.labelSmall
          ?.copyWith(fontWeight: FontWeight.w600, color: AppColors.muted),
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
      secondary: AppColors.navy,
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
      secondary: AppColors.navy,
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

/// Convenient semantic text styles used across widgets (design-guide names).
extension AppTextStyles on BuildContext {
  TextStyle get bigNumber => const TextStyle(
      fontWeight: FontWeight.w800, fontSize: 30, color: AppColors.ink, letterSpacing: -0.5);
  TextStyle get sectionLabel => const TextStyle(
      fontWeight: FontWeight.w800,
      fontSize: 13,
      color: AppColors.ink,
      letterSpacing: 0.8);
  TextStyle get rowTitle =>
      const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textStrong);
  TextStyle get caption =>
      const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.muted);
}
