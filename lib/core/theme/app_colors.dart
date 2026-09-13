import 'dart:ui';

/// Brand palette for the "calm clinical minimal" redesign (backlog #14).
///
/// Provisional until the real logo lands — picked to read as distinct from
/// Flutter's default Material blue while staying calm/trustworthy for a
/// pharmacy, and to pair well with the flat character illustrations in
/// `core/illustrations/`.
class AppColors {
  static const Color primary = Color(0xFF0E7C7B);
  static const Color secondary = Color(0xFF2A9D8F);

  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color error = Color(0xFFD32F2F);

  static const Color background = Color(0xFFFBFCFA);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF1C2A27);
  static const Color textSecondary = Color(0xFF5F6F6B);

  /// Top-to-bottom app background gradient, applied once in [MyApp]'s
  /// `builder` (behind every screen's now-transparent `Scaffold`) rather
  /// than per-screen.
  static const Color gradientLightTop = Color(0xFFE7F5F3);
  static const Color gradientLightBottom = Color(0xFFFBFCFA);
  static const Color gradientDarkTop = Color(0xFF0A1615);
  static const Color gradientDarkBottom = Color(0xFF11201E);
}
