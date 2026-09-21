import 'package:flutter/material.dart';

/// Colour palette for the "bright & rounded" redesign (backlog #22).
///
/// One place for every brand colour, so screens never hard-code hex values:
/// button/progress gradients, the pastel + vivid accent pairs used for tiles
/// and chips, and the per-tab background and large-card gradients.
abstract final class AppPalette {
  /// Dark ink used for text on the light pastel gradients.
  static const Color ink = Color(0xFF12312B);

  /// Background of the sticky bottom action bars (cart, checkout, product
  /// detail): the same soft white tint as the bottom nav in light mode.
  static Color barColor(ThemeData theme) => theme.brightness == Brightness.dark
      ? theme.colorScheme.surfaceContainer
      : Colors.white.withValues(alpha: 0.85);

  // Buttons: one deeper-orange gradient everywhere, white text on top.
  static const Color orangeStart = Color(0xFFE85A0C);
  static const Color orangeEnd = Color(0xFFFF8A2B);
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [orangeStart, orangeEnd],
  );

  // Progress: amber → teal → green (the order-details bar, now app-wide).
  static const Color amber = Color(0xFFFFB020);
  static const Color teal = Color(0xFF1FB59B);
  static const Color green = Color(0xFF3CC46A);
  static const LinearGradient progressGradient = LinearGradient(
    colors: [amber, teal, green],
    stops: [0, 0.6, 1],
  );
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

/// The one app-wide background and large-card gradient (mint → peach in
/// light mode, deep teal → brown in dark mode).
abstract final class AppGradients {
  static const _top = Color(0xFF9FE8D0);
  static const _bottom = Color(0xFFFFD3B8);
  static const _cardEnd = Color(0xFFCFF3E4);
  static const _darkTop = Color(0xFF0F3A33);
  static const _darkBottom = Color(0xFF3A2418);
  static const _darkCardStart = Color(0xFF243230);
  static const _darkCardEnd = Color(0xFF1D3B35);

  static LinearGradient background(Brightness b) => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: b == Brightness.dark ? [_darkTop, _darkBottom] : [_top, _bottom],
  );

  /// Horizontal gradient for large cards.
  static LinearGradient card(Brightness b) => LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: b == Brightness.dark
        ? [_darkCardStart, _darkCardEnd]
        : [const Color(0xFFFFFFFF), _cardEnd],
  );
}
