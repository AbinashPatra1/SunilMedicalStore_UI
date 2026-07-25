import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/profile/domain/lab_test.dart';
import 'package:sunil_medical_store/features/profile/presentation/widgets/status_chip.dart';

/// Detail of a single lab test, with a (placeholder) download-invoice action.
class LabTestDetailScreen extends StatelessWidget {
  const LabTestDetailScreen({super.key, required this.labTest});

  final LabTest? labTest;

  @override
  Widget build(BuildContext context) {
    final test = labTest;
    if (test == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lab Test')),
        body: const Center(child: Text('Lab test not found.')),
      );
    }

    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(test.name)),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        children: [
          Row(
            children: [
              Expanded(child: Text(test.labName, style: theme.textTheme.titleMedium)),
              StatusChip(label: test.status.label, positive: test.status != LabTestStatus.cancelled),
            ],
          ),
          const SizedBox(height: AppConstants.spacingXs),
          Text(
            'Booked on ${DateFormat('d MMM yyyy').format(test.bookedOn)}',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          Text('Parameters', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppConstants.spacingSm),
          Card(
            child: Column(
              children: [
                for (final parameter in test.parameters)
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.check_circle_outline, color: theme.colorScheme.primary),
                    title: Text(parameter),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Card(
            child: ListTile(
              title: Text('Amount', style: theme.textTheme.titleMedium),
              trailing: Text('₹${test.amount}', style: theme.textTheme.titleMedium),
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(content: Text('Invoice download coming soon')));
            },
            icon: const Icon(Icons.download_outlined),
            label: const Text('Download invoice'),
          ),
        ],
      ),
    );
  }
}
