import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';

/// Search entry point on the dashboard — tapping it invokes [onTap], which
/// navigates to [SearchScreen] (a plain-text field here; the actual query
/// input lives on that screen).
class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingMd,
            vertical: AppConstants.spacingMd,
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: AppConstants.spacingSm),
              Text(
                'Search medicines, health products…',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
