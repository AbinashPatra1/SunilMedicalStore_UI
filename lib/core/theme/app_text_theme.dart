import 'package:flutter/material.dart';

/// The app's Material 3 type scale.
///
/// Colors are intentionally left unset: [ThemeData] and the `Material`
/// widget fill them in from the active [ColorScheme] (`onSurface`), so the
/// same [TextTheme] can be shared by both the light and dark themes.
abstract final class AppTextTheme {
  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 57, height: 64 / 57, fontWeight: FontWeight.w400),
    displayMedium: TextStyle(fontSize: 45, height: 52 / 45, fontWeight: FontWeight.w400),
    displaySmall: TextStyle(fontSize: 36, height: 44 / 36, fontWeight: FontWeight.w400),
    headlineLarge: TextStyle(fontSize: 32, height: 40 / 32, fontWeight: FontWeight.w600),
    headlineMedium: TextStyle(fontSize: 28, height: 36 / 28, fontWeight: FontWeight.w600),
    headlineSmall: TextStyle(fontSize: 24, height: 32 / 24, fontWeight: FontWeight.w600),
    titleLarge: TextStyle(fontSize: 22, height: 28 / 22, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w500),
    titleSmall: TextStyle(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w400),
    bodyMedium: TextStyle(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w400),
    bodySmall: TextStyle(fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w400),
    labelLarge: TextStyle(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w500),
    labelMedium: TextStyle(fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w500),
    labelSmall: TextStyle(fontSize: 11, height: 16 / 11, fontWeight: FontWeight.w500),
  );
}
