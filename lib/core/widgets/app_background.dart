import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/theme/app_palette.dart';

/// Paints the [tab]'s background gradient behind [child] and tells
/// descendants (via [AppTabScope]) which palette to use for large cards.
/// Changing [tab] cross-fades the gradient.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.tab, required this.child});

  final AppTab tab;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return AppTabScope(
      tab: tab,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: AppTabPalette.of(tab).background(brightness),
        ),
        child: child,
      ),
    );
  }
}

/// Exposes the current [AppTab] so shared widgets (e.g. `GradientCard`)
/// can pick up the tab's colours without every caller passing them in.
class AppTabScope extends InheritedWidget {
  const AppTabScope({super.key, required this.tab, required super.child});

  final AppTab tab;

  static AppTab of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppTabScope>()?.tab ??
      AppTab.pharmacy;

  @override
  bool updateShouldNotify(AppTabScope oldWidget) => tab != oldWidget.tab;
}
