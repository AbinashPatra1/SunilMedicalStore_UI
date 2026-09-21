import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/theme/app_palette.dart';

/// Paints the app's background gradient behind [child].
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: AppGradients.background(Theme.of(context).brightness)),
      child: child,
    );
  }
}
