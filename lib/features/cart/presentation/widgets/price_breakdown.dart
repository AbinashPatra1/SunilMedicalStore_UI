import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/cart/presentation/providers/cart_providers.dart';

/// Order price breakdown: subtotal, discount, delivery, platform fee (if
/// applicable), and total.
class PriceBreakdown extends ConsumerWidget {
  const PriceBreakdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtotal = ref.watch(cartSubtotalProvider);
    final discount = ref.watch(cartDiscountProvider);
    final delivery = ref.watch(cartDeliveryFeeLineProvider);
    final platformFee = ref.watch(cartPlatformFeeLineProvider);
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
            _FeeRow(label: 'Delivery', fee: delivery),
            if (platformFee.amount > 0) ...[
              const SizedBox(height: AppConstants.spacingSm),
              _FeeRow(label: 'Platform fee', fee: platformFee),
            ],
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

/// A price row backed by a [CartFeeLine] — shows a plain "FREE"/"₹amount"
/// normally, or (when the admin has explicitly waived a nonzero fee) the
/// original amount struck through next to "FREE", mirroring the MRP-vs-price
/// strikethrough already used on product cards.
class _FeeRow extends StatelessWidget {
  const _FeeRow({required this.label, required this.fee});

  final String label;
  final CartFeeLine fee;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showStrikethrough = fee.waived && fee.amount > 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Row(
          children: [
            if (showStrikethrough) ...[
              Text(
                '₹${fee.amount}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: AppConstants.spacingXs),
            ],
            Text(
              fee.charged == 0 ? 'FREE' : '₹${fee.charged}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: showStrikethrough ? theme.colorScheme.primary : null,
                fontWeight: showStrikethrough ? FontWeight.w600 : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
