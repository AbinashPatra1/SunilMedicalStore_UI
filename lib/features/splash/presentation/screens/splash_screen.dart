import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';

/// Branded loading screen shown at app startup while the auth session is
/// resolved (`AuthStatus.unknown`). The router's redirect keeps the user here
/// until auth settles, then sends them to the login screen or their role's
/// home — so this screen is pure UI with no navigation logic of its own.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/branding/logo.png', width: 220),
            const SizedBox(height: AppConstants.spacingXl),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
