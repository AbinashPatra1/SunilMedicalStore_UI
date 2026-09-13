import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/lab_tests/domain/lab_test.dart';

/// A tappable card summarizing a lab test in the catalog list.
class LabTestCard extends StatelessWidget {
  const LabTestCard({super.key, required this.test, required this.onTap});

  final LabTest test;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final discount = test.discountPercent;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    ),
                    child: Icon(Icons.biotech_outlined, color: theme.colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: AppConstants.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(test.name, style: theme.textTheme.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                        Text(
                          '${test.labName} • ${test.parameters.length} parameter(s)',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Row(
                children: [
                  _Chip(icon: Icons.water_drop_outlined, label: test.sampleType),
                  const SizedBox(width: AppConstants.spacingSm),
                  _Chip(icon: Icons.schedule_outlined, label: test.reportTime),
                ],
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Row(
                children: [
                  Text('₹${test.price}', style: theme.textTheme.titleSmall),
                  if (discount != null) ...[
                    const SizedBox(width: AppConstants.spacingSm),
                    Text(
                      '₹${test.mrp}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingSm),
                    Text(
                      '$discount% off',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 2),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
