import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';

/// Small colored status pill (e.g. Delivered / Completed / Cancelled).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, this.positive = true});

  final String label;

  /// Positive statuses use the primary tone; negative ones the error tone.
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = positive ? theme.colorScheme.primaryContainer : theme.colorScheme.errorContainer;
    final fg = positive ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onErrorContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingSm, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
      ),
      child: Text(label, style: theme.textTheme.labelSmall?.copyWith(color: fg)),
    );
  }
}
