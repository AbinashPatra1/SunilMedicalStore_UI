import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/cart/presentation/providers/cart_providers.dart';

/// Order price breakdown: subtotal, discount, delivery, and total.
class PriceBreakdown extends ConsumerWidget {
  const PriceBreakdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtotal = ref.watch(cartSubtotalProvider);
    final discount = ref.watch(cartDiscountProvider);
    final delivery = ref.watch(cartDeliveryProvider);
    final total = ref.watch(cartTotalProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Column(
          children: [
            _Row(label: 'Subtotal', value: '₹$subtotal'),
            if (discount > 0) ...[
              const SizedBox(height: AppConstants.spacingSm),
              _Row(label: 'Discount', value: '−₹$discount', highlight: true),
            ],
            const SizedBox(height: AppConstants.spacingSm),
            _Row(label: 'Delivery', value: delivery == 0 ? 'FREE' : '₹$delivery'),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppConstants.spacingSm),
              child: Divider(height: 1),
            ),
            _Row(label: 'Total', value: '₹$total', bold: true),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.bold = false,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool bold;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = bold ? theme.textTheme.titleMedium : theme.textTheme.bodyMedium;
    final valueStyle = highlight ? style?.copyWith(color: theme.colorScheme.primary) : style;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: valueStyle),
      ],
    );
  }
}
