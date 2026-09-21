import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/illustrations/product_illustration.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/core/utils/delivery_estimate.dart';
import 'package:sunil_medical_store/features/medicines/domain/product.dart';

/// Full-width list item for a product in the category / catalog list.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onAdd,
    required this.onTap,
  });

  final Product product;
  final VoidCallback onAdd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final oos = product.isOutOfStock;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: Opacity(
            opacity: oos ? 0.5 : 1.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProductIllustration.forProduct(product: product, width: 64, height: 64),
                    const SizedBox(width: AppConstants.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name, style: theme.textTheme.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                          Text(
                            product.brand,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                          if (product.packSize != null)
                            Text(
                              product.packSize!,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          if (product.requiresPrescription || oos) ...[
                            const SizedBox(height: AppConstants.spacingXs),
                            Row(
                              children: [
                                if (product.requiresPrescription) const _RxBadge(),
                                if (product.requiresPrescription && oos)
                                  const SizedBox(width: AppConstants.spacingXs),
                                if (oos) const _OutOfStockBadge(),
                              ],
                            ),
                          ],
                          const SizedBox(height: AppConstants.spacingSm),
                          _PriceRow(product: product),
                          if (!oos) ...[
                            const SizedBox(height: AppConstants.spacingXs),
                            Text(
                              deliveryEstimateLabel(),
                              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingSm),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonal(
                    onPressed: oos ? null : onAdd,
                    child: const Text('Add'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OutOfStockBadge extends StatelessWidget {
  const _OutOfStockBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingSm, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
      ),
      child: Text(
        'Out of stock',
        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

/// Rounded placeholder thumbnail used until real product images exist.
class _RxBadge extends StatelessWidget {
  const _RxBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingSm, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
      ),
      child: Text(
        'Rx required',
        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onErrorContainer),
      ),
    );
  }
}

/// Shared price display: selling price, struck-through MRP, and discount.
class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final discount = product.discountPercent;

    return Row(
      children: [
        Text('₹${product.price}', style: theme.textTheme.titleSmall),
        if (discount != null) ...[
          const SizedBox(width: AppConstants.spacingSm),
          Text(
            '₹${product.mrp}',
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
    );
  }
}
