import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/routes/app_router.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/core/theme/app_palette.dart';
import 'package:sunil_medical_store/core/theme/app_theme.dart';
import 'package:sunil_medical_store/features/profile/presentation/providers/theme_controller.dart';

/// App root: wires the GoRouter instance from [routerProvider] into a
/// [MaterialApp.router] and applies the light/dark theme.
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Defaults to light regardless of the device setting (see
      // `themeModeProvider`) — the user can switch to dark from Profile >
      // Settings, and the choice persists across restarts.
      themeMode: themeMode,
      routerConfig: router,
      // Fallback gradient for routes outside the tab shells (splash, login), in place of a
      // flat scaffold color (backlog #14). Painted once here — every
      // Scaffold's own background is transparent (see `AppTheme`) so this
      // shows through on every screen without each one needing its own copy.
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppGradients.background(brightness),
          ),
          child: child,
        );
      },
    );
  }
}
