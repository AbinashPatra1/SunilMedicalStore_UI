import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/theme/app_colors.dart';

/// Small helpers that sit on top of [AppColors] for the "premium
/// healthcare" refresh (backlog #23): the accent button style reserved for
/// cart/checkout actions, and the pastel + vivid accent pairs used for
/// category tiles, avatars and status chips (unchanged from backlog #22 —
/// the new palette keeps these multi-coloured).
abstract final class AppPalette {
  /// Dark, readable text colour for the light pastel [AppAccent] tiles.
  static const Color ink = AppColors.textPrimary;

  /// Background of the sticky bottom action bars (cart, checkout, product
  /// detail) and the bottom nav bar — plain white in light mode, a dark
  /// surface tone in dark mode.
  static Color barColor(ThemeData theme) => theme.brightness == Brightness.dark
      ? theme.colorScheme.surfaceContainer
      : Colors.white;

  /// Style for buttons that add to the cart or complete a purchase ("Add",
  /// "Add to cart", "Payment", "Order Now", "Reorder") — the one place
  /// [AppColors.accent] is used. Every other primary button stays the
  /// theme's default flat [AppColors.primary].
  static ButtonStyle cartActionButtonStyle(BuildContext context) {
    final base =
        Theme.of(context).filledButtonTheme.style ?? const ButtonStyle();
    return base.copyWith(
      backgroundColor: const WidgetStatePropertyAll(AppColors.accent),
      foregroundColor: const WidgetStatePropertyAll(Colors.white),
    );
  }
}

/// A pastel tile colour with the vivid colour of its icon badge.
class AppAccent {
  const AppAccent(this.pastel, this.vivid);

  final Color pastel;
  final Color vivid;

  static const mint = AppAccent(Color(0xFFD8F5EA), Color(0xFF2BB58C));
  static const peach = AppAccent(Color(0xFFFFE3D6), Color(0xFFFF8A65));
  static const sky = AppAccent(Color(0xFFDCEFFD), Color(0xFF4FA8F0));
  static const lavender = AppAccent(Color(0xFFE6E1FF), Color(0xFF8B7CF6));
  static const pink = AppAccent(Color(0xFFFFE0EA), Color(0xFFF06292));
  static const amber = AppAccent(Color(0xFFFFF0CC), Color(0xFFFFB020));

  static const all = [mint, peach, sky, lavender, pink, amber];

  /// Dark, readable shade of [vivid] for text/icons drawn on [pastel].
  Color get ink => Color.lerp(vivid, AppPalette.ink, 0.45)!;

  /// A stable accent for [seed] (a name, say), so the same person or item
  /// always gets the same colour.
  static AppAccent forSeed(String seed) {
    var h = 0;
    for (final c in seed.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return all[h % all.length];
  }
}
