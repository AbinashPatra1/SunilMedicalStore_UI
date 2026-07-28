import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/routes/app_routes.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/cart/presentation/providers/cart_providers.dart';
import 'package:sunil_medical_store/features/lab_tests/domain/lab_test.dart';
import 'package:sunil_medical_store/features/lab_tests/presentation/providers/lab_test_providers.dart';

/// Details of a bookable lab test, with an Add-to-cart action.
class LabTestCatalogDetailScreen extends ConsumerWidget {
  const LabTestCatalogDetailScreen({super.key, required this.testId});

  final String testId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testAsync = ref.watch(labTestByIdProvider(testId));

    return testAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => Scaffold(
        appBar: AppBar(title: const Text('Lab Test')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load the test.'),
              const SizedBox(height: AppConstants.spacingSm),
              TextButton(
                onPressed: () => ref.invalidate(labTestByIdProvider(testId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (test) => _Detail(test: test),
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.test});

  final LabTest test;

  void _addToCart(BuildContext context, WidgetRef ref) {
    ref.read(cartProvider.notifier).addLabTest(test);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${test.name} added to cart'),
          action: SnackBarAction(label: 'View cart', onPressed: () => context.go(AppRoutes.cart)),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final discount = test.discountPercent;

    return Scaffold(
      appBar: AppBar(title: Text(test.name)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppConstants.spacingLg),
              children: [
                Text(test.name, style: theme.textTheme.titleLarge),
                const SizedBox(height: AppConstants.spacingXs),
                Text(
                  test.labName,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
                ),
                const SizedBox(height: AppConstants.spacingMd),
                Text(test.description, style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppConstants.spacingLg),
                Card(
                  child: Column(
                    children: [
                      _InfoRow(icon: Icons.water_drop_outlined, label: 'Sample', value: test.sampleType),
                      const Divider(height: 1),
                      _InfoRow(icon: Icons.schedule_outlined, label: 'Report', value: test.reportTime),
                      const Divider(height: 1),
                      _InfoRow(
                        icon: Icons.restaurant_outlined,
                        label: 'Fasting',
                        value: test.fastingRequired ? 'Required (10-12 hrs)' : 'Not required',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.spacingLg),
                Text('Parameters included (${test.parameters.length})', style: theme.textTheme.titleMedium),
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
              ],
            ),
          ),
          Material(
            elevation: 8,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingLg),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text('₹${test.price}', style: theme.textTheme.titleLarge),
                            if (discount != null) ...[
                              const SizedBox(width: AppConstants.spacingSm),
                              Text(
                                '₹${test.mrp}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (discount != null)
                          Text('$discount% off', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary)),
                      ],
                    ),
                    const SizedBox(width: AppConstants.spacingLg),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _addToCart(context, ref),
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Add to cart'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      trailing: Text(value, style: theme.textTheme.bodyMedium),
    );
  }
}
