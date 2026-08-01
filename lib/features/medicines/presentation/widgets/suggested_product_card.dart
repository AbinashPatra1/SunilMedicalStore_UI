import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/medicines/domain/product.dart';

/// Compact, fixed-width product card for the horizontal "Suggested" row.
class SuggestedProductCard extends StatelessWidget {
  const SuggestedProductCard({
    super.key,
    required this.product,
    required this.onAdd,
    required this.onTap,
  });

  final Product product;
  final VoidCallback onAdd;
  final VoidCallback onTap;

  static const double width = 156;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final oos = product.isOutOfStock;

    return SizedBox(
      width: width,
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          onTap: onTap,
          child: Opacity(
            opacity: oos ? 0.5 : 1.0,
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingSm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 72,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    ),
                    child: Icon(Icons.medication, color: theme.colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(height: AppConstants.spacingSm),
                  Text(
                    product.name,
                    style: theme.textTheme.labelLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    product.brand,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppConstants.spacingXs),
                  Row(
                    children: [
                      Text('₹${product.price}', style: theme.textTheme.titleSmall),
                      if (product.discountPercent != null) ...[
                        const SizedBox(width: AppConstants.spacingXs),
                        Expanded(
                          child: Text(
                            '₹${product.mrp}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              decoration: TextDecoration.lineThrough,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingSm),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: oos ? null : onAdd,
                      child: Text(oos ? 'Out of stock' : 'Add'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
