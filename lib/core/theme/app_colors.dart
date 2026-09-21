import 'dart:ui';

/// Brand palette for the "calm clinical minimal" redesign (backlog #14).
///
/// Provisional until the real logo lands — picked to read as distinct from
/// Flutter's default Material blue while staying calm/trustworthy for a
/// pharmacy, and to pair well with the flat character illustrations in
/// `core/illustrations/`.
class AppColors {
  static const Color primary = Color(0xFF0A6B5E);
  static const Color secondary = Color(0xFF1FB59B);

  /// The button colour (`AppPalette.orangeStart`) as a `#RRGGBB` string — for APIs that want a hex color
  /// literal rather than a [Color] (e.g. the Razorpay checkout SDK's theme).
  static const String primaryHex = '#E85A0C';

  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color error = Color(0xFFD32F2F);

  static const Color background = Color(0xFFFBFCFA);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF1C2A27);
  static const Color textSecondary = Color(0xFF5F6F6B);

  /// Top-to-bottom app background gradient, applied once in [MyApp]'s
  /// `builder` (behind every screen's now-transparent `Scaffold`) rather
  /// than per-screen. Deliberately more visible than a bare tint so it
  /// reads as a gradient rather than a near-solid color.
  static const Color gradientLightTop = Color(0xFF9FE8D0);
  static const Color gradientLightBottom = Color(0xFFFFD3B8);
  static const Color gradientDarkTop = Color(0xFF0F3A33);
  static const Color gradientDarkBottom = Color(0xFF3A2418);
}
