import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/medicines/presentation/providers/medicine_providers.dart';
import 'package:sunil_medical_store/features/medicines/presentation/widgets/suggested_product_card.dart';

/// Horizontal "Suggested for you" row on the dashboard.
class SuggestedProducts extends ConsumerWidget {
  const SuggestedProducts({super.key, required this.onAdd});

  /// Called with the product name when its Add button is tapped.
  final ValueChanged<String> onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final suggestedAsync = ref.watch(suggestedProductsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Suggested for you', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppConstants.spacingMd),
        suggestedAsync.when(
          loading: () => const SizedBox(
            height: 250,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => const SizedBox(
            height: 60,
            child: Center(child: Text('Could not load suggestions.')),
          ),
          data: (products) => SizedBox(
            height: 250,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppConstants.spacingMd),
              itemBuilder: (context, index) {
                final product = products[index];
                return SuggestedProductCard(
                  product: product,
                  onAdd: () => onAdd(product.name),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
