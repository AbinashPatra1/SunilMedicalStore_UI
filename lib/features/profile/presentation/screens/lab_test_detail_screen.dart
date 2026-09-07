import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/profile/domain/lab_test.dart';
import 'package:sunil_medical_store/features/profile/presentation/providers/profile_providers.dart';
import 'package:sunil_medical_store/features/profile/presentation/widgets/status_chip.dart';
import 'package:url_launcher/url_launcher.dart';

/// Detail of a single lab test, with a download-invoice action.
class LabTestDetailScreen extends ConsumerStatefulWidget {
  const LabTestDetailScreen({super.key, required this.labTest});

  final LabTest? labTest;

  @override
  ConsumerState<LabTestDetailScreen> createState() => _LabTestDetailScreenState();
}

class _LabTestDetailScreenState extends ConsumerState<LabTestDetailScreen> {
  bool _downloadingInvoice = false;

  Future<void> _downloadInvoice() async {
    final test = widget.labTest;
    if (test == null) return;
    setState(() => _downloadingInvoice = true);
    try {
      final url = await ref.read(profileRepositoryProvider).labTestInvoiceUrl(test.id);
      final launched = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Could not open the invoice.')));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _downloadingInvoice = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final test = widget.labTest;
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
            'Scheduled for ${DateFormat('d MMM yyyy').format(test.bookedOn)}'
            '${test.timeSlot != null ? ' • ${test.timeSlot}' : ''}',
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
            onPressed: _downloadingInvoice ? null : _downloadInvoice,
            icon: _downloadingInvoice
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.download_outlined),
            label: const Text('Download invoice'),
          ),
        ],
      ),
    );
  }
}
