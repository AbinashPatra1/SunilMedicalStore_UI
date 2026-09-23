import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/lab_tests/domain/lab_test.dart';

/// Admin-side lab-test row: name + lab + sample/report meta + price. Tap the
/// whole tile to edit.
class LabTestAdminTile extends StatelessWidget {
  const LabTestAdminTile({super.key, required this.test, required this.onTap});

  final LabTest test;
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(test.name, style: theme.textTheme.titleSmall),
                    Text(
                      test.labName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingXs),
                    Text(
                      '${test.sampleType} • ${test.reportTime}'
                      '${test.fastingRequired ? ' • Fasting required' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Text('₹${test.price}', style: theme.textTheme.titleSmall),
            ],
          ),
        ),
      ),
    );
  }
}
