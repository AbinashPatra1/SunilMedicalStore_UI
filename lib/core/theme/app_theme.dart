import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sunil_medical_store/core/theme/app_colors.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/core/theme/app_text_theme.dart';

/// Builds the app's light and dark [ThemeData].
///
/// Brand colors come from [AppColors]; [ColorScheme.fromSeed] fills in the
/// rest of the Material 3 tonal palette around them. "Premium healthcare"
/// refresh (backlog #23): flat colours everywhere — a plain scaffold
/// background instead of the gradient painted in backlog #22, flat tonal
/// cards, and flat pill-shaped buttons (teal by default; see
/// `AppPalette.cartActionButtonStyle` for the orange cart/checkout accent).
abstract final class AppTheme {
  static ThemeData get light => _build(_lightColorScheme, AppColors.background);

  static ThemeData get dark =>
      _build(_darkColorScheme, AppColors.darkBackground);

  static final ColorScheme _lightColorScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        tertiary: AppColors.accent,
        onTertiary: Colors.white,
        error: AppColors.error,
        surface: AppColors.surface,
      );

  static final ColorScheme _darkColorScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFF2DD4BF),
        onPrimary: const Color(0xFF042F2E),
        secondary: const Color(0xFF5EEAD4),
        onSecondary: const Color(0xFF042F2E),
        tertiary: const Color(0xFFFBBF24),
        onTertiary: const Color(0xFF451A03),
        error: AppColors.error,
        surface: AppColors.darkSurface,
      );

  /// Every filled/elevated button: a flat teal fill with white text,
  /// pill-shaped. Buttons that touch the cart/checkout instead use
  /// `AppPalette.cartActionButtonStyle` for the orange accent.
  static ButtonStyle _filledButtonStyle(ColorScheme colorScheme) {
    return ElevatedButton.styleFrom(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
      disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
      elevation: 0,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingLg,
        vertical: AppConstants.spacingSm,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      ),
    );
  }

  static ThemeData _build(ColorScheme colorScheme, Color scaffoldBackground) {
    // Manrope: a geometric, modern sans — swapped in for the system default
    // to move away from the "generic Flutter app" look. Keeps the existing
    // Material 3 type scale (sizes/weights/line-heights in [AppTextTheme]),
    // just changes the typeface. Fetched over the network on first use and
    // cached by `google_fonts` — acceptable for now, revisit bundling the
    // font as an asset if a fully offline cold-start matters later.
    final textTheme = GoogleFonts.manropeTextTheme(AppTextTheme.textTheme)
        .apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
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
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _filledButtonStyle(colorScheme),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _filledButtonStyle(colorScheme),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingLg,
            vertical: AppConstants.spacingSm,
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
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.5,
        ),
        selectedColor: colorScheme.primaryContainer,
        labelStyle: textTheme.labelLarge,
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: colorScheme.onPrimaryContainer,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        ),
      ),
    );
  }
}
