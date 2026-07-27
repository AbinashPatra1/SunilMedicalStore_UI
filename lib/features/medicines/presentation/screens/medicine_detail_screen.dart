import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/routes/app_routes.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/cart/presentation/providers/cart_providers.dart';
import 'package:sunil_medical_store/features/medicines/domain/product.dart';
import 'package:sunil_medical_store/features/medicines/presentation/providers/medicine_providers.dart';
import 'package:sunil_medical_store/features/medicines/presentation/widgets/suggested_product_card.dart';

/// Full details for a single product, with similar items and an add-to-cart
/// action. Resolved from the catalog by [productId].
class MedicineDetailScreen extends ConsumerWidget {
  const MedicineDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(allProductsProvider);

    return catalogAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => Scaffold(
        appBar: AppBar(title: const Text('Medicine')),
        body: const Center(child: Text('Could not load the product.')),
      ),
      data: (products) {
        Product? product;
        for (final p in products) {
          if (p.id == productId) product = p;
        }
        if (product == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Medicine')),
            body: const Center(child: Text('Product not found.')),
          );
        }
        final similar = products
            .where((p) => p.category == product!.category && p.id != product.id)
            .toList();
        return _Detail(product: product, similar: similar);
      },
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.product, required this.similar});

  final Product product;
  final List<Product> similar;

  void _added(BuildContext context, WidgetRef ref, Product p) {
    ref.read(cartProvider.notifier).addProduct(p);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${p.name} added to cart'),
          action: SnackBarAction(label: 'View cart', onPressed: () => context.go(AppRoutes.cart)),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final discount = product.discountPercent;

    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppConstants.spacingLg),
              children: [
                // Image placeholder.
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                  ),
                  child: Icon(Icons.medication, size: 72, color: theme.colorScheme.onPrimaryContainer),
                ),
                const SizedBox(height: AppConstants.spacingLg),
                Text(product.name, style: theme.textTheme.titleLarge),
                const SizedBox(height: AppConstants.spacingXs),
                Text(
                  product.brand,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
                ),
                if (product.requiresPrescription) ...[
                  const SizedBox(height: AppConstants.spacingSm),
                  _Badge(label: 'Prescription required', color: theme.colorScheme.errorContainer, onColor: theme.colorScheme.onErrorContainer),
                ],
                const SizedBox(height: AppConstants.spacingMd),
                Row(
                  children: [
                    Text('₹${product.price}', style: theme.textTheme.headlineSmall),
                    if (discount != null) ...[
                      const SizedBox(width: AppConstants.spacingMd),
                      Text(
                        '₹${product.mrp}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacingSm),
                      Text('$discount% off', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
                    ],
                  ],
                ),
                if (product.description.isNotEmpty) ...[
                  const SizedBox(height: AppConstants.spacingLg),
                  Text(product.description, style: theme.textTheme.bodyMedium),
                ],
                if (product.composition != null)
                  _Section(title: 'Composition', child: Text(product.composition!, style: theme.textTheme.bodyMedium)),
                if (product.dosage != null)
                  _Section(title: 'Dosage', child: Text(product.dosage!, style: theme.textTheme.bodyMedium)),
                if (product.ingredients.isNotEmpty)
                  _Section(
                    title: 'Ingredients',
                    child: Wrap(
                      spacing: AppConstants.spacingSm,
                      runSpacing: AppConstants.spacingSm,
                      children: [for (final i in product.ingredients) Chip(label: Text(i))],
                    ),
                  ),
                if (similar.isNotEmpty) ...[
                  const SizedBox(height: AppConstants.spacingLg),
                  Text('Similar products', style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppConstants.spacingMd),
                  SizedBox(
                    height: 250,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: similar.length,
                      separatorBuilder: (_, _) => const SizedBox(width: AppConstants.spacingMd),
                      itemBuilder: (context, index) {
                        final p = similar[index];
                        return SuggestedProductCard(
                          product: p,
                          onAdd: () => _added(context, ref, p),
                          onTap: () => context.push('${AppRoutes.medicineDetail}/${p.id}'),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          Material(
            elevation: 8,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingLg),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _added(context, ref, product),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Add to cart'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppConstants.spacingLg),
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppConstants.spacingSm),
        child,
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, required this.onColor});

  final String label;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingSm, vertical: 2),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppConstants.radiusSm)),
        child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: onColor)),
      ),
    );
  }
}
