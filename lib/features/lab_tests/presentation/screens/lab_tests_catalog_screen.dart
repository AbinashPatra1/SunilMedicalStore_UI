import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/routes/app_routes.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/lab_tests/presentation/providers/lab_test_providers.dart';
import 'package:sunil_medical_store/features/lab_tests/presentation/widgets/lab_test_card.dart';

/// Lab Tests tab: browse the catalog of bookable tests.
class LabTestsCatalogScreen extends ConsumerWidget {
  const LabTestsCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final catalogAsync = ref.watch(labTestCatalogProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Lab Tests')),
      body: catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _ErrorView(onRetry: () => ref.invalidate(labTestCatalogProvider)),
        data: (tests) => ListView.separated(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          itemCount: tests.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: AppConstants.spacingMd),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Book a lab test', style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppConstants.spacingXs),
                  Text(
                    'Home sample collection • accurate reports',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              );
            }
            final test = tests[index - 1];
            return LabTestCard(
              test: test,
              onTap: () => context.push('${AppRoutes.labTests}/${test.id}'),
            );
          },
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Could not load lab tests.'),
          const SizedBox(height: AppConstants.spacingSm),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
