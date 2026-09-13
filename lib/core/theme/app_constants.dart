/// Design tokens shared across the app: spacing, radii, and motion timings.
///
/// Widgets should reference these instead of hard-coded numbers so the
/// spacing scale stays consistent as new features are added.
abstract final class AppConstants {
  static const String appName = 'Sunil Medical Store';

  // Spacing scale (logical pixels).
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
  static const double spacingXxl = 48;

  // Corner radii — bumped up for the "calm clinical minimal" redesign
  // (backlog #14): softer, more generous rounding than stock Material.
  static const double radiusSm = 4;
  static const double radiusMd = 16;
  static const double radiusLg = 24;
  static const double radiusXl = 28;
  static const double radiusFull = 999;

  // Motion.
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Networking (used once the ASP.NET Core backend is integrated).
  static const Duration apiTimeout = Duration(seconds: 30);
}
