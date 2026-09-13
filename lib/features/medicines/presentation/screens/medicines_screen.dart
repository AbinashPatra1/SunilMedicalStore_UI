import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/illustrations/search_empty_illustration.dart';
import 'package:sunil_medical_store/core/routes/app_routes.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/cart/presentation/providers/cart_providers.dart';
import 'package:sunil_medical_store/features/medicines/presentation/providers/medicine_providers.dart';
import 'package:sunil_medical_store/features/medicines/presentation/widgets/product_card.dart';

/// Product catalog for a category (or all products when [category] is null).
///
/// Reached from the dashboard by tapping a category tile, the promo banner, or
/// the search entry point.
class MedicinesScreen extends ConsumerWidget {
  const MedicinesScreen({super.key, this.category});

  final String? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsByCategoryProvider(category ?? ''));

    return Scaffold(
      appBar: AppBar(title: Text(category ?? 'Medicines')),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          onRetry: () => ref.invalidate(productsByCategoryProvider(category ?? '')),
        ),
        data: (products) {
          if (products.isEmpty) {
            final theme = Theme.of(context);
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingXl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SearchEmptyIllustration(size: 96),
                    const SizedBox(height: AppConstants.spacingMd),
                    Text(
                      'No products available yet.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppConstants.spacingLg),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppConstants.spacingMd),
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                onTap: () => context.push('${AppRoutes.medicineDetail}/${product.id}'),
                onAdd: () {
                  ref.read(cartProvider.notifier).addProduct(product);
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(content: Text('${product.name} added to cart')),
                    );
                },
              );
            },
          );
        },
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
          const Text('Could not load products.'),
          const SizedBox(height: AppConstants.spacingSm),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
