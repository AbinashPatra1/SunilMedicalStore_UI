import 'dart:ui';

/// Brand palette for the "premium healthcare" refresh (backlog #23),
/// replacing the brighter orange/pastel palette from backlog #22.
///
/// Richer greens, softer neutrals, one accent colour reserved for
/// cart/checkout actions — see `docs` for the source design reference.
class AppColors {
  static const Color primary = Color(0xFF0F766E);
  static const Color secondary = Color(0xFF14B8A6);

  /// Reserved for buttons that add to the cart or complete a purchase
  /// ("Add", "Add to cart", "Payment", "Order Now", "Reorder") — see
  /// [AppPalette.cartActionButtonStyle] in `app_palette.dart`. Every other
  /// primary button uses [primary].
  static const Color accent = Color(0xFFF59E0B);

  /// [primary] as a `#RRGGBB` string — for APIs that want a hex color
  /// literal rather than a [Color] (e.g. the Razorpay checkout SDK's theme).
  static const String primaryHex = '#0F766E';

  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color error = Color(0xFFD32F2F);

  static const Color background = Color(0xFFF8FDFA);
  static const Color surface = Color(0xFFE6F2ED);

  static const Color textPrimary = Color(0xFF374151);
  static const Color textSecondary = Color(0xFF6B7280);

  static const Color darkBackground = Color(0xFF0B1917);
  static const Color darkSurface = Color(0xFF10201D);
}
