import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/illustrations/happy_discount_illustration.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';

/// Promotional banner on the dashboard landing page (dummy content).
class PromoBanner extends StatelessWidget {
  const PromoBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Up to 25% off on medicines',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingXs),
                  Text(
                    'Order your monthly refills and save more.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingMd),
                  FilledButton(onPressed: onTap, child: const Text('Order now')),
                ],
              ),
            ),
            const HappyDiscountIllustration(size: 88),
          ],
        ),
      ),
    );
  }
}
