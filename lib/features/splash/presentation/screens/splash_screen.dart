import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/core/theme/app_palette.dart';

/// Branded loading screen shown at app startup while the auth session is
/// resolved (`AuthStatus.unknown`). The router's redirect keeps the user here
/// until auth settles, then sends them to the login screen or their role's
/// home — so this screen is pure UI with no navigation logic of its own.
///
/// Full branded layout per the "premium healthcare" refresh (backlog #23):
/// logo, wordmark + tagline, a row of what-we-do icons, a loading spinner,
/// and a closing cursive signature line.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingLg,
          ),
          child: Column(
            children: [
              const Spacer(flex: 3),
              Center(child: Image.asset('assets/branding/logo.png', width: 180)),
              const SizedBox(height: AppConstants.spacingLg),
              Text(
                AppConstants.appName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppConstants.spacingXs),
              Text(
                'Your Health, Our Priority',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(flex: 2),
              const _FeatureIconRow(),
              const Spacer(flex: 2),
              const CircularProgressIndicator(),
              const Spacer(flex: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Care Closer to You',
                    style: GoogleFonts.dancingScript(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    'Healthier Today\nBrighter Tomorrow',
                    textAlign: TextAlign.right,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingLg),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureIconRow extends StatelessWidget {
  const _FeatureIconRow();

  static const _items = [
    (Icons.medication_outlined, 'Medicines', AppAccent.mint),
    (Icons.biotech_outlined, 'Lab Tests', AppAccent.sky),
    (Icons.medical_services_outlined, 'Doctor Visits', AppAccent.lavender),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final (icon, label, accent) in _items)
          Column(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: accent.pastel,
                child: Icon(icon, color: accent.ink),
              ),
              const SizedBox(height: AppConstants.spacingXs),
              Text(label, style: theme.textTheme.labelMedium),
            ],
          ),
      ],
    );
  }
}
