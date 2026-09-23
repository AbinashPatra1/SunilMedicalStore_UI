import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/models/order.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/cart/presentation/providers/cart_providers.dart';
import 'package:sunil_medical_store/features/profile/presentation/providers/profile_providers.dart';

const _reasons = [
  'Damaged or defective',
  'Wrong item delivered',
  'Expired or near expiry',
  'No longer needed',
  'Other',
];

/// Lets the customer pick which delivered items (and how many units) to
/// return, and why. Pops with the updated [Order] on success.
class ReturnOrderScreen extends ConsumerStatefulWidget {
  const ReturnOrderScreen({super.key, required this.order});

  final Order? order;

  @override
  ConsumerState<ReturnOrderScreen> createState() => _ReturnOrderScreenState();
}

class _ReturnOrderScreenState extends ConsumerState<ReturnOrderScreen> {
  /// productId -> units to return (absent = not selected).
  final _selected = <String, int>{};
  final _details = TextEditingController();
  String? _reason;
  bool _submitting = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  List<OrderItem> get _returnable => widget.order!.items
      .where((i) => !i.isLabTest && i.productId != null)
      .toList();

  Future<void> _submit() async {
    final order = widget.order!;
    final lines = [
      for (final item in _returnable)
        if (_selected.containsKey(item.productId))
          ReturnLine(
            productId: item.productId!,
            name: item.name,
            quantity: _selected[item.productId]!,
          ),
    ];
    final note = _details.text.trim();
    final reason = note.isEmpty ? _reason! : '${_reason!} — $note';

    setState(() => _submitting = true);
    try {
      final updated = await ref
          .read(orderRepositoryProvider)
          .requestReturn(order.id, lines: lines, reason: reason);
      ref.invalidate(pastOrdersProvider);
      ref.invalidate(orderByIdProvider(order.id));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Return requested. We will update you once it is reviewed.',
            ),
          ),
        );
      context.pop(updated);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Return items')),
        body: const Center(child: Text('Order not found.')),
      );
    }
    final theme = Theme.of(context);
    final items = _returnable;
    final canSubmit = _selected.isNotEmpty && _reason != null && !_submitting;

    return Scaffold(
      appBar: AppBar(title: Text('Return · ${order.orderNumber}')),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        children: [
          Text(
            'Select the items to return',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppConstants.spacingSm),
          if (items.isEmpty)
            const Text('None of the items in this order can be returned.')
          else
            for (final item in items)
              _ItemRow(
                item: item,
                quantity: _selected[item.productId],
                enabled: !_submitting,
                onToggle: (on) => setState(() {
                  if (on) {
                    _selected[item.productId!] = item.quantity;
                  } else {
                    _selected.remove(item.productId);
                  }
                }),
                onQuantity: (q) =>
                    setState(() => _selected[item.productId!] = q),
              ),
          const SizedBox(height: AppConstants.spacingLg),
          DropdownButtonFormField<String>(
            initialValue: _reason,
            decoration: const InputDecoration(labelText: 'Reason for return'),
            items: [
              for (final r in _reasons)
                DropdownMenuItem(value: r, child: Text(r)),
            ],
            onChanged: _submitting ? null : (v) => setState(() => _reason = v),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          TextField(
            controller: _details,
            enabled: !_submitting,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Anything else we should know? (optional)',
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          FilledButton(
            onPressed: canSubmit ? _submit : null,
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Request return'),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.quantity,
    required this.enabled,
    required this.onToggle,
    required this.onQuantity,
  });

  final OrderItem item;

  /// Units selected, or `null` when the item isn't selected.
  final int? quantity;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onQuantity;

  @override
  Widget build(BuildContext context) {
    final selected = quantity != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingSm,
          vertical: 4,
        ),
        child: Row(
          children: [
            Checkbox(
              value: selected,
              onChanged: enabled ? (v) => onToggle(v ?? false) : null,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                  Text(
                    'Ordered ${item.quantity} · ₹${item.price} each',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (selected && item.quantity > 1) ...[
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: enabled && quantity! > 1
                    ? () => onQuantity(quantity! - 1)
                    : null,
              ),
              Text('$quantity'),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: enabled && quantity! < item.quantity
                    ? () => onQuantity(quantity! + 1)
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
