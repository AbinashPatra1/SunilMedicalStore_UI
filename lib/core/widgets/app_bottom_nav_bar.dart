import 'package:flutter/material.dart';

/// One destination in an [AppBottomNavBar].
class AppNavDestination {
  const AppNavDestination({required this.icon, required this.selectedIcon, required this.label});

  /// Usually an [Icon] (or a [Badge]-wrapped one, e.g. the customer Cart tab).
  final Widget icon;
  final Widget selectedIcon;
  final String label;
}

/// Material 3 styled bottom navigation bar — a drop-in visual replacement
/// for [NavigationBar] that never wraps a label to a second line.
///
/// [NavigationDestination.label] is a plain `String`; Flutter renders it as
/// `Text(label, style: textStyle)` with no `maxLines`/`overflow` (see
/// `navigation_bar.dart`'s `_NavigationDestinationBuilder.buildLabel`), so a
/// longer label like "Appointments" wraps to two lines whenever a device is
/// narrow enough (or the user's text-scale setting is large enough — labels
/// are clamped to 1.3x, not 1.0x) that it doesn't fit the destination's
/// column width. There's no public hook to fix that through `NavigationBar`
/// itself, so this reimplements the same look (M3 token values below) with
/// each label wrapped in a [FittedBox] that shrinks-to-fit instead of
/// wrapping or truncating — the label always stays on one line, in full,
/// on every device.
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

    return Material(
      color: colors.surfaceContainer,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 80,
          child: Row(
            children: [
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: _NavItem(
                    destination: destinations[i],
                    selected: i == selectedIndex,
                    onTap: () => onDestinationSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.destination, required this.selected, required this.onTap});

  final AppNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

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
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    softWrap: false,
                    style: textTheme.labelMedium?.copyWith(color: labelColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
