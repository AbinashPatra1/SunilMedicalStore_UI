import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/core/theme/app_palette.dart';
import 'package:sunil_medical_store/core/widgets/app_background.dart';

/// A large rounded card with the current tab's horizontal pastel gradient.
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
    final gradient = AppTabPalette.of(AppTabScope.of(context)).card(brightness);
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Ink(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: radius,
          border: Border.all(
            color: Colors.white.withValues(
              alpha: brightness == Brightness.dark ? 0.06 : 0.7,
            ),
          ),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
