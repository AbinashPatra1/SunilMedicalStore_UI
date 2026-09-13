import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/cart/domain/cart_item.dart';

/// A single cart line: product, price, a quantity stepper, and line total.
class CartItemTile extends StatelessWidget {
  const CartItemTile({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              ),
              child: Icon(
                item.kind == CartItemKind.labTest ? Icons.biotech_outlined : Icons.medication_outlined,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: AppConstants.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: theme.textTheme.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  Text(
                    item.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  if (item.kind == CartItemKind.labTest && item.scheduledDate != null && item.timeSlot != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${DateFormat('d MMM').format(item.scheduledDate!)} • ${item.timeSlot}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ],
                  const SizedBox(height: AppConstants.spacingSm),
                  Row(
                    children: [
                      Text('₹${item.price}', style: theme.textTheme.titleSmall),
                      const Spacer(),
                      _QuantityStepper(
                        quantity: item.quantity,
                        onIncrement: onIncrement,
                        onDecrement: onDecrement,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Remove',
              icon: const Icon(Icons.delete_outline),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(icon: Icons.remove, onPressed: onDecrement),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingSm),
            child: Text('$quantity', style: theme.textTheme.titleSmall),
          ),
          _StepperButton(icon: Icons.add, onPressed: onIncrement),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingSm),
        child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
