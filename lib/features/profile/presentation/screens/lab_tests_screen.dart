import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/routes/app_routes.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/profile/domain/lab_test.dart';
import 'package:sunil_medical_store/features/profile/presentation/providers/profile_providers.dart';
import 'package:sunil_medical_store/features/profile/presentation/widgets/status_chip.dart';

/// Profile > Lab Tests: the customer's lab test history. Tapping a test opens
/// its detail screen.
class LabTestsScreen extends ConsumerWidget {
  const LabTestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testsAsync = ref.watch(labTestsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Lab Tests')),
      body: testsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error is ApiException ? error.message : 'Could not load lab tests.'),
              const SizedBox(height: AppConstants.spacingSm),
              TextButton(
                onPressed: () => ref.invalidate(labTestsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (tests) {
          if (tests.isEmpty) {
            return const Center(child: Text('No lab tests yet.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(labTestsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppConstants.spacingLg),
              itemCount: tests.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppConstants.spacingMd),
              itemBuilder: (context, index) {
                final test = tests[index];
                return _LabTestCard(
                  test: test,
                  onTap: () => context.push(AppRoutes.profileLabTestDetail, extra: test),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _LabTestCard extends StatelessWidget {
  const _LabTestCard({required this.test, required this.onTap});

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(test.name, style: theme.textTheme.titleSmall)),
                  StatusChip(label: test.status.label, positive: test.status != LabTestStatus.cancelled),
                ],
              ),
              if (test.bookingNumber != null) ...[
                const SizedBox(height: AppConstants.spacingXs),
                Text(
                  test.bookingNumber!,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: AppConstants.spacingXs),
              Text(
                '${test.labName} • ${DateFormat('d MMM yyyy').format(test.bookedOn)}'
                '${test.timeSlot != null ? ' • ${test.timeSlot}' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Row(
                children: [
                  Text('₹${test.amount}', style: theme.textTheme.titleSmall),
                  const Spacer(),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
