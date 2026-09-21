import 'package:flutter/material.dart';

/// Colour palette for the "bright & rounded" redesign (backlog #22).
///
/// One place for every brand colour, so screens never hard-code hex values:
/// button/progress gradients, the pastel + vivid accent pairs used for tiles
/// and chips, and the per-tab background and large-card gradients.
abstract final class AppPalette {
  /// Dark ink used for text on the light pastel gradients.
  static const Color ink = Color(0xFF12312B);

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
}

/// The bottom-nav tabs that each get their own background gradient.
enum AppTab { pharmacy, labTests, appointments, cart, profile, admin }

/// Background and large-card colours for one [AppTab].
class AppTabPalette {
  const AppTabPalette({
    required this.top,
    required this.bottom,
    required this.cardEnd,
    required this.darkTop,
    required this.darkBottom,
    required this.darkCardEnd,
  });

  final Color top;
  final Color bottom;

  /// Right-hand colour of a large card's horizontal gradient (the left is
  /// near-white in light mode).
  final Color cardEnd;
  final Color darkTop;
  final Color darkBottom;
  final Color darkCardEnd;

  static const _pharmacy = AppTabPalette(
    top: Color(0xFF9FE8D0),
    bottom: Color(0xFFFFD3B8),
    cardEnd: Color(0xFFCFF3E4),
    darkTop: Color(0xFF0F3A33),
    darkBottom: Color(0xFF3A2418),
    darkCardEnd: Color(0xFF1D3B35),
  );
  static const _labTests = AppTabPalette(
    top: Color(0xFFA8D8FF),
    bottom: Color(0xFFD4C8FF),
    cardEnd: Color(0xFFD6EAFF),
    darkTop: Color(0xFF102A48),
    darkBottom: Color(0xFF231C4A),
    darkCardEnd: Color(0xFF1C3350),
  );
  static const _appointments = AppTabPalette(
    top: Color(0xFFCFC2FF),
    bottom: Color(0xFFFFB8D2),
    cardEnd: Color(0xFFE9E2FF),
    darkTop: Color(0xFF231C4A),
    darkBottom: Color(0xFF4A1A32),
    darkCardEnd: Color(0xFF2E2650),
  );
  static const _cart = AppTabPalette(
    top: Color(0xFFFFCFA3),
    bottom: Color(0xFFFFE58F),
    cardEnd: Color(0xFFFFE9C9),
    darkTop: Color(0xFF4A2A10),
    darkBottom: Color(0xFF4A3F10),
    darkCardEnd: Color(0xFF3F3220),
  );
  static const _profile = AppTabPalette(
    top: Color(0xFF8FE3D6),
    bottom: Color(0xFFB5D9FF),
    cardEnd: Color(0xFFD3F3EE),
    darkTop: Color(0xFF0F3A3A),
    darkBottom: Color(0xFF102A48),
    darkCardEnd: Color(0xFF1B3838),
  );

  static AppTabPalette of(AppTab tab) => switch (tab) {
    AppTab.pharmacy => _pharmacy,
    AppTab.labTests => _labTests,
    AppTab.appointments => _appointments,
    AppTab.cart => _cart,
    AppTab.profile => _profile,
    // The admin console is a working tool: one calm gradient for every tab.
    AppTab.admin => _profile,
  };

  LinearGradient background(Brightness b) => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: b == Brightness.dark ? [darkTop, darkBottom] : [top, bottom],
  );

  LinearGradient card(Brightness b) => LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: b == Brightness.dark
        ? [const Color(0xFF243230), darkCardEnd]
        : [const Color(0xFFFFFFFF), cardEnd],
  );
}
