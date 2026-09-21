import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/models/order.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/core/widgets/refund_status_banner.dart';
import 'package:sunil_medical_store/features/admin/delivery/presentation/providers/delivery_settings_providers.dart';
import 'package:sunil_medical_store/features/admin/orders/domain/admin_order.dart';
import 'package:sunil_medical_store/features/admin/orders/presentation/providers/admin_order_providers.dart';
import 'package:sunil_medical_store/features/admin/presentation/widgets/status_swipe_bar.dart';
import 'package:sunil_medical_store/features/profile/presentation/widgets/order_detail_sections.dart';

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
  late AdminOrder _order = widget.existing;
  bool _busy = false;
  String? _error;

  Future<void> _advance() async {
    final next = _order.status.next;
    if (next == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final updated = await ref.read(adminOrderRepositoryProvider).updateStatus(_order.id, next);
      ref.invalidate(adminOrdersProvider);
      if (mounted) {
        setState(() => _order = updated);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Order marked ${next.label}')));
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel order?'),
        content: Text('This will cancel order ${_order.orderNumber}. This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep order'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.onErrorContainer,
              backgroundColor: Theme.of(dialogContext).colorScheme.errorContainer,
              backgroundBuilder: flatButtonBackground,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final updated = await ref.read(adminOrderRepositoryProvider).updateStatus(_order.id, OrderStatus.cancelled);
      ref.invalidate(adminOrdersProvider);
      if (mounted) {
        setState(() => _order = updated);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Order cancelled')));
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final o = _order;
    final advanceLabel = o.status.advanceLabel;
    final settings = ref.watch(deliverySettingsProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(o.orderNumber)),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        children: [
          OrderSummaryCard(status: o.status, placedOn: o.placedOn, deliveredOn: o.deliveredOn),
          if (o.refundStatus != null) ...[
            const SizedBox(height: AppConstants.spacingMd),
            RefundStatusBanner(status: o.refundStatus!),
          ],
          const SizedBox(height: AppConstants.spacingLg),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(o.userName),
              subtitle: Text(o.userPhone),
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          Text('Items', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppConstants.spacingSm),
          OrderItemsBillCard(
            items: o.items,
            subtotal: o.subtotal,
            discount: o.discount,
            delivery: o.delivery,
            platformFee: o.platformFee,
            total: o.total,
            paymentMethod: o.paymentMethod,
          ),
          const SizedBox(height: AppConstants.spacingLg),
          if (advanceLabel != null)
            StatusSwipeBar(
              label: advanceLabel,
              enabled: !_busy,
              onConfirm: _advance,
            ),
          if (_error != null) ...[
            const SizedBox(height: AppConstants.spacingMd),
            Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: AppConstants.spacingSm),
          OutlinedButton.icon(
            onPressed: (_busy || o.status == OrderStatus.cancelled) ? null : _cancel,
            style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancel order'),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          OrderPolicySection(
            order: OrderPolicyInput(status: o.status, deliveredOn: o.deliveredOn, orderNumber: o.orderNumber),
            settings: settings,
            showCancelNote: false,
          ),
          const SizedBox(height: AppConstants.spacingLg),
          OrderInfoCard(address: o.deliveryAddress?.formatted, orderNumber: o.orderNumber, placedOn: o.placedOn),
        ],
      ),
    );
  }
}
