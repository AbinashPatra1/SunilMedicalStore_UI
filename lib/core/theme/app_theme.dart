import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sunil_medical_store/core/theme/app_colors.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/core/theme/app_palette.dart';
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

  static final ColorScheme _lightColorScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.error,
        surface: AppColors.surface,
        primaryContainer: AppAccent.mint.pastel,
        onPrimaryContainer: const Color(0xFF0A4A40),
        secondaryContainer: AppAccent.peach.pastel,
        onSecondaryContainer: const Color(0xFF7A2E0A),
        tertiaryContainer: AppAccent.lavender.pastel,
        onTertiaryContainer: const Color(0xFF2E2470),
      );

  static final ColorScheme _darkColorScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ).copyWith(
        // Deep versions of the light mint/peach/lavender containers, so the nav
        // pill, chips and tonal buttons keep their colour identity in the dark.
        primaryContainer: const Color(0xFF0F4D43),
        onPrimaryContainer: AppAccent.mint.pastel,
        secondaryContainer: const Color(0xFF5A2E18),
        onSecondaryContainer: AppAccent.peach.pastel,
        tertiaryContainer: const Color(0xFF3A2F73),
        onTertiaryContainer: AppAccent.lavender.pastel,
      );

  /// Every filled/elevated button: the deeper-orange gradient with white
  /// text, pill-shaped. Applied through `backgroundBuilder` so no call site
  /// needs to know about it. Buttons that must look different (destructive
  /// dialog actions) pass [flatButtonBackground] to opt out.
  static ButtonStyle _gradientButtonStyle(ColorScheme colorScheme) {
    return ButtonStyle(
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
      shadowColor: const WidgetStatePropertyAll(Colors.transparent),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? colorScheme.onSurface.withValues(alpha: 0.38)
            : Colors.white,
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: AppConstants.spacingLg,
          vertical: AppConstants.spacingSm,
        ),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        ),
      ),
      backgroundBuilder: (context, states, child) {
        final disabled = states.contains(WidgetState.disabled);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.radiusFull),
            gradient: disabled ? null : AppPalette.buttonGradient,
            color: disabled
                ? colorScheme.onSurface.withValues(alpha: 0.12)
                : null,
          ),
          child: child,
        );
      },
    );
  }

  static ThemeData _build(ColorScheme colorScheme) {
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
        color: colorScheme.brightness == Brightness.light
            ? Colors.white.withValues(alpha: 0.82)
            : colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _gradientButtonStyle(colorScheme),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _gradientButtonStyle(colorScheme),
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

/// `backgroundBuilder` that draws nothing extra, so a button keeps its own
/// `backgroundColor` instead of the themed orange gradient.
Widget flatButtonBackground(
  BuildContext context,
  Set<WidgetState> states,
  Widget? child,
) => child!;
