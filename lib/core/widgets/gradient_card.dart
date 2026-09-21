import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/core/theme/app_palette.dart';

/// A large rounded card with the app's horizontal pastel gradient.
/// Use for summaries and hero blocks; product and list rows stay flat
/// (plain [Card]).
class GradientCard extends StatelessWidget {
  const GradientCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppConstants.spacingMd),
    this.margin,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final radius = BorderRadius.circular(AppConstants.radiusLg);
    final gradient = AppGradients.card(brightness);
    return Padding(
      padding: margin ?? const EdgeInsets.all(4),
      // A plain DecoratedBox rather than `Ink`: an Ink decoration keeps the
      // size it had when first laid out, so a card that grows afterwards
      // (e.g. a row appearing once data loads) painted short.
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: radius,
          border: Border.all(
            color: Colors.white.withValues(
              alpha: brightness == Brightness.dark ? 0.06 : 0.7,
            ),
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
