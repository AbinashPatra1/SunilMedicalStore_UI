import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/routes/app_routes.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/cart/presentation/providers/cart_providers.dart';
import 'package:sunil_medical_store/features/cart/presentation/widgets/cart_item_tile.dart';
import 'package:sunil_medical_store/features/cart/presentation/widgets/price_breakdown.dart';
import 'package:sunil_medical_store/features/cart/presentation/widgets/promo_code_field.dart';

/// Cart tab: line items, promo code, price breakdown, and checkout entry.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: items.isEmpty
          ? _EmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppConstants.spacingLg),
                    children: [
                      for (final item in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppConstants.spacingMd),
                          child: CartItemTile(
                            item: item,
                            onIncrement: () => ref.read(cartProvider.notifier).increment(item.id),
                            onDecrement: () => ref.read(cartProvider.notifier).decrement(item.id),
                            onRemove: () => ref.read(cartProvider.notifier).remove(item.id),
                          ),
                        ),
                      const SizedBox(height: AppConstants.spacingSm),
                      const PromoCodeField(),
                      const SizedBox(height: AppConstants.spacingLg),
                      const PriceBreakdown(),
                    ],
                  ),
                ),
                _PaymentBar(
                  total: ref.watch(cartTotalProvider),
                  onPressed: () => context.push(AppRoutes.cartCheckout),
                ),
              ],
            ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: AppConstants.spacingMd),
            Text('Your cart is empty', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppConstants.spacingXs),
            Text(
              'Add medicines and health products to get started.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingLg),
            FilledButton(
              onPressed: () => context.go(AppRoutes.medicines),
              child: const Text('Browse medicines'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentBar extends StatelessWidget {
  const _PaymentBar({required this.total, required this.onPressed});

  final int total;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
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
                  Text('Total', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  Text('₹$total', style: theme.textTheme.titleLarge),
                ],
              ),
              const SizedBox(width: AppConstants.spacingLg),
              Expanded(
                child: FilledButton(
                  onPressed: onPressed,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppConstants.spacingSm),
                    child: Text('Payment'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
