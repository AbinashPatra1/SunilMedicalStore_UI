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
    final productAsync = ref.watch(productByIdProvider(productId));

    return productAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => Scaffold(
        appBar: AppBar(title: const Text('Medicine')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load the product.'),
              const SizedBox(height: AppConstants.spacingSm),
              TextButton(
                onPressed: () => ref.invalidate(productByIdProvider(productId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (product) => _Detail(product: product),
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.product});

  final Product product;

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
    final similarAsync = ref.watch(similarProductsProvider(product.id));

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
                if (product.isOutOfStock) ...[
                  const SizedBox(height: AppConstants.spacingSm),
                  _Badge(label: 'Out of stock', color: theme.colorScheme.surfaceContainerHighest, onColor: theme.colorScheme.onSurfaceVariant),
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
                similarAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.only(top: AppConstants.spacingLg),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (similar) {
                    if (similar.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                    );
                  },
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
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: product.isOutOfStock ? null : () => _added(context, ref, product),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: Text(product.isOutOfStock ? 'Out of stock' : 'Add to cart'),
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
