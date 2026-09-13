import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sunil_medical_store/core/theme/app_colors.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/core/theme/app_text_theme.dart';

/// Builds the app's light and dark [ThemeData].
///
/// Brand colors come from [AppColors]; [ColorScheme.fromSeed] fills in the
/// rest of the Material 3 tonal palette around them. Part of the "calm
/// clinical minimal" redesign (backlog #14): flat tonal cards (no drop
/// shadow), pill-shaped buttons, and a transparent scaffold/app-bar so the
/// gradient background painted once in [MyApp]'s `builder` shows through
/// every screen instead of each Scaffold painting an opaque background.
abstract final class AppTheme {
  static ThemeData get light => _build(_lightColorScheme);

  static ThemeData get dark => _build(_darkColorScheme);

  static final ColorScheme _lightColorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    error: AppColors.error,
    surface: AppColors.surface,
  );

  static final ColorScheme _darkColorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
  );

  static ThemeData _build(ColorScheme colorScheme) {
    // Manrope: a geometric, modern sans — swapped in for the system default
    // to move away from the "generic Flutter app" look. Keeps the existing
    // Material 3 type scale (sizes/weights/line-heights in [AppTextTheme]),
    // just changes the typeface. Fetched over the network on first use and
    // cached by `google_fonts` — acceptable for now, revisit bundling the
    // font as an asset if a fully offline cold-start matters later.
    final textTheme = GoogleFonts.manropeTextTheme(AppTextTheme.textTheme).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      // Transparent so `MyApp`'s gradient background paints through every
      // screen instead of being covered by an opaque Scaffold.
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingLg,
            vertical: AppConstants.spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusFull),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingLg,
            vertical: AppConstants.spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusFull),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingLg,
            vertical: AppConstants.spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusFull),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMd,
          vertical: AppConstants.spacingMd,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
