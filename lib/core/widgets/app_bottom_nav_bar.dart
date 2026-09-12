import 'package:flutter/material.dart';

/// One destination in an [AppBottomNavBar].
class AppNavDestination {
  const AppNavDestination({required this.icon, required this.selectedIcon, required this.label});

  /// Usually an [Icon] (or a [Badge]-wrapped one, e.g. the customer Cart tab).
  final Widget icon;
  final Widget selectedIcon;
  final String label;
}

/// Below this shared shrink factor, a label is no longer legible enough to
/// keep — every label is hidden instead (icon-only) rather than let text
/// keep shrinking towards illegibility.
const double _kMinLegibleLabelScale = 0.75;

/// Material 3 styled bottom navigation bar — a drop-in visual replacement
/// for [NavigationBar] that never wraps a label to a second line.
///
/// [NavigationDestination.label] is a plain `String`; Flutter renders it as
/// `Text(label, style: textStyle)` with no `maxLines`/`overflow` (see
/// `navigation_bar.dart`'s `_NavigationDestinationBuilder.buildLabel`), so a
/// longer label like "Appointments" wraps to two lines whenever a device is
/// narrow enough that it doesn't fit the destination's column width. There's
/// no public hook to fix that through `NavigationBar` itself, so this
/// reimplements the same look (M3 token values below).
///
/// The first version of this fix wrapped each label in its own independent
/// `FittedBox`, which stopped the wrapping but introduced a subtler bug:
/// every tab shrank to fit *its own* label, so "Appointments" (the longest
/// label) rendered visibly smaller than "Cart" or "Orders" on the same bar —
/// inconsistent, not just non-wrapping. This version instead measures every
/// destination's label up front and applies **one shared shrink factor**
/// (the minimum needed by the longest label) across all of them, so every
/// label in the bar is always the same size. If even that shared factor
/// drops below [_kMinLegibleLabelScale], labels are dropped entirely and the
/// bar falls back to icon-only — shrinking text indefinitely stops being
/// readable long before it stops fitting.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AppNavDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final baseStyle = textTheme.labelMedium ?? const TextStyle(fontSize: 12);
    // Match NavigationBar's own accessibility clamp so this doesn't grow
    // unboundedly at large system font-scale settings.
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);
    final scaledBaseFontSize = scaler.scale(baseStyle.fontSize ?? 12);

    return Material(
      color: colors.surfaceContainer,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 80,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columnWidth = constraints.maxWidth / destinations.length;
              // 4px padding on each side of the label (see _NavItem).
              final availableLabelWidth = columnWidth - 8;

              var sharedScale = 1.0;
              for (final destination in destinations) {
                final painter = TextPainter(
                  text: TextSpan(
                    text: destination.label,
                    style: baseStyle.copyWith(fontSize: scaledBaseFontSize),
                  ),
                  textDirection: Directionality.of(context),
                  maxLines: 1,
                )..layout();
                if (painter.width > 0) {
                  final needed = availableLabelWidth / painter.width;
                  if (needed < sharedScale) sharedScale = needed;
                }
              }
              sharedScale = sharedScale.clamp(0.0, 1.0);
              final showLabels = sharedScale >= _kMinLegibleLabelScale;

              return Row(
                children: [
                  for (var i = 0; i < destinations.length; i++)
                    Expanded(
                      child: _NavItem(
                        destination: destinations[i],
                        selected: i == selectedIndex,
                        onTap: () => onDestinationSelected(i),
                        labelFontSize: showLabels ? scaledBaseFontSize * sharedScale : null,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
    required this.labelFontSize,
  });

  final AppNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  /// Pre-computed, shared across every destination in the bar. `null` means
  /// the label is hidden entirely (icon-only fallback).
  final double? labelFontSize;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final iconColor = selected ? colors.onSecondaryContainer : colors.onSurfaceVariant;
    final labelColor = selected ? colors.onSurface : colors.onSurfaceVariant;

    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: ShapeDecoration(
                  color: selected ? colors.secondaryContainer : Colors.transparent,
                  shape: const StadiumBorder(),
                ),
                child: IconTheme(
                  data: IconThemeData(size: 24, color: iconColor),
                  child: selected ? destination.selectedIcon : destination.icon,
                ),
              ),
              if (labelFontSize != null) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    textScaler: TextScaler.noScaling,
                    style: textTheme.labelMedium?.copyWith(color: labelColor, fontSize: labelFontSize),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
