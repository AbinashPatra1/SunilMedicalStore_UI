import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';

/// Branded loading screen shown at app startup while auth state and
/// remote config are resolved. Currently a static placeholder; it will
/// redirect to [AppRoutes.dashboard] or [AppRoutes.login] once auth is wired
/// up.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_pharmacy_rounded,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text(AppConstants.appName, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppConstants.spacingXl),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
