import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';

/// A tappable card that links from the dashboard to a feature area.
class DashboardNavCard extends StatelessWidget {
  const DashboardNavCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: AppConstants.spacingMd),
              Expanded(child: Text(label, style: theme.textTheme.titleMedium)),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
