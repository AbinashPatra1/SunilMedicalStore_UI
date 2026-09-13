import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/routes/app_router.dart';
import 'package:sunil_medical_store/core/theme/app_colors.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/core/theme/app_theme.dart';

/// App root: wires the GoRouter instance from [routerProvider] into a
/// [MaterialApp.router] and applies the light/dark theme.
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
      // A single top-to-bottom gradient behind the whole app, in place of a
      // flat scaffold color (backlog #14). Painted once here — every
      // Scaffold's own background is transparent (see `AppTheme`) so this
      // shows through on every screen without each one needing its own copy.
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? const [AppColors.gradientDarkTop, AppColors.gradientDarkBottom]
                  : const [AppColors.gradientLightTop, AppColors.gradientLightBottom],
            ),
          ),
          child: child,
        );
      },
    );
  }
}
