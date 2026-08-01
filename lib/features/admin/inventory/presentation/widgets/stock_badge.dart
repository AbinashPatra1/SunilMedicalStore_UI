import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';

/// A colored badge summarizing the stock level of an inventory item.
///
/// * `stock == 0` → red "Out of stock"
/// * `stock <= [lowStockThreshold]` → amber "Low: N"
/// * otherwise → green "In stock: N"
class StockBadge extends StatelessWidget {
  const StockBadge({
    super.key,
    required this.stock,
    this.lowStockThreshold = 10,
  });

  final int stock;
  final int lowStockThreshold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (label, background, foreground) = switch (stock) {
      <= 0 => (
        'Out of stock',
        theme.colorScheme.errorContainer,
        theme.colorScheme.onErrorContainer,
      ),
      _ when stock <= lowStockThreshold => (
        'Low: $stock',
        Colors.orange.shade100,
        Colors.orange.shade900,
      ),
      _ => (
        'In stock: $stock',
        theme.colorScheme.primaryContainer,
        theme.colorScheme.onPrimaryContainer,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingSm, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: foreground),
      ),
    );
  }
}
