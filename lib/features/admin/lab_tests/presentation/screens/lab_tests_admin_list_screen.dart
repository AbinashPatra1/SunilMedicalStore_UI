import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/routes/app_routes.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/admin/lab_tests/presentation/providers/lab_test_admin_providers.dart';
import 'package:sunil_medical_store/features/admin/lab_tests/presentation/widgets/lab_test_admin_tile.dart';

/// Admin > More > Lab Tests: lists the full lab-test catalog. Tapping a row
/// edits; the FAB adds a new test.
class LabTestsAdminListScreen extends ConsumerWidget {
  const LabTestsAdminListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(adminLabTestsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Lab Tests')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.adminLabTestAdd),
        icon: const Icon(Icons.add),
        label: const Text('Add lab test'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error is ApiException ? error.message : 'Could not load lab tests.'),
              const SizedBox(height: AppConstants.spacingSm),
              TextButton(
                onPressed: () => ref.invalidate(adminLabTestsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (tests) {
          if (tests.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingXl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.biotech_outlined, size: 56, color: theme.colorScheme.primary),
                    const SizedBox(height: AppConstants.spacingMd),
                    Text('No lab tests', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppConstants.spacingXs),
                    Text(
                      'Add a test with the button below.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminLabTestsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.spacingLg,
                AppConstants.spacingSm,
                AppConstants.spacingLg,
                AppConstants.spacingXxl + AppConstants.spacingLg,
              ),
              itemCount: tests.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppConstants.spacingSm),
              itemBuilder: (context, index) {
                final test = tests[index];
                return LabTestAdminTile(
                  test: test,
                  onTap: () => context.push('${AppRoutes.adminLabTestEdit}/${test.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
