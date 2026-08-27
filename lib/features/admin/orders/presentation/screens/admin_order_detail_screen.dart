import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/models/order.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/admin/orders/domain/admin_order.dart';
import 'package:sunil_medical_store/features/admin/orders/presentation/providers/admin_order_providers.dart';

/// Admin views an order and can change its status — advance the fulfilment
/// lifecycle (`created → processing → shipped → delivered`) or cancel it.
class AdminOrderDetailScreen extends ConsumerWidget {
  const AdminOrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminOrderByIdProvider(orderId));
    return async.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Order')),
        body: Center(
          child: Text(error is ApiException ? error.message : 'Could not load order.'),
        ),
      ),
      data: (order) => _DetailForm(existing: order),
    );
  }
}

class _DetailForm extends ConsumerStatefulWidget {
  const _DetailForm({required this.existing});

  final AdminOrder existing;

  @override
  ConsumerState<_DetailForm> createState() => _DetailFormState();
}

class _DetailFormState extends ConsumerState<_DetailForm> {
  late OrderStatus _status;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _status = widget.existing.status;
  }

  bool get _statusChanged => _status != widget.existing.status;

  Future<void> _save() async {
    if (!_statusChanged) {
      context.pop();
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(adminOrderRepositoryProvider).updateStatus(widget.existing.id, _status);
      ref.invalidate(adminOrderByIdProvider(widget.existing.id));
      ref.invalidate(adminOrdersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Order updated')));
        context.pop();
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final o = widget.existing;

    return Scaffold(
      appBar: AppBar(title: Text(o.orderNumber)),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(o.userName, style: theme.textTheme.titleSmall),
                  Text(
                    o.userPhone,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppConstants.spacingSm),
                  Text(
                    'Placed on ${DateFormat('EEE, d MMM yyyy').format(o.placedOn)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (o.paymentMethod != null)
                    Text('Payment: ${o.paymentMethod}', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          Text('Items', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppConstants.spacingSm),
          Card(
            child: Column(
              children: [
                for (final item in o.items)
                  ListTile(
                    title: Text(item.name),
                    subtitle: Text('Qty ${item.quantity} × ₹${item.price}'),
                    trailing: Text('₹${item.lineTotal}', style: theme.textTheme.titleSmall),
                  ),
                const Divider(height: 1),
                ListTile(
                  title: Text('Total', style: theme.textTheme.titleMedium),
                  trailing: Text('₹${o.total}', style: theme.textTheme.titleMedium),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          Text('Status', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppConstants.spacingSm),
          Wrap(
            spacing: AppConstants.spacingSm,
            children: [
              for (final s in OrderStatus.values)
                ChoiceChip(
                  label: Text(s.label),
                  selected: _status == s,
                  onSelected: _saving ? null : (_) => setState(() => _status = s),
                ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: AppConstants.spacingMd),
            Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: AppConstants.spacingLg),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save changes'),
          ),
        ],
      ),
    );
  }
}
