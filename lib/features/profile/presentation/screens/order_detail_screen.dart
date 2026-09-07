import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/core/models/order.dart';
import 'package:sunil_medical_store/features/cart/presentation/providers/cart_providers.dart';
import 'package:sunil_medical_store/features/profile/presentation/providers/profile_providers.dart';
import 'package:sunil_medical_store/features/profile/presentation/widgets/status_chip.dart';
import 'package:url_launcher/url_launcher.dart';

/// Detail of a single order, with a download-invoice action and — while the
/// order is still cancellable — a Cancel action.
class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.order});

  final Order? order;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  late Order? _order = widget.order;
  bool _cancelling = false;
  bool _downloadingInvoice = false;

  Future<void> _downloadInvoice() async {
    final order = _order;
    if (order == null) return;
    setState(() => _downloadingInvoice = true);
    try {
      final url = await ref.read(profileRepositoryProvider).orderInvoiceUrl(order.id);
      final launched = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Could not open the invoice.')));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _downloadingInvoice = false);
    }
  }

  Future<void> _cancel() async {
    final order = _order;
    if (order == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel order?'),
        content: Text('This will cancel order ${order.orderNumber}. This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep order'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    try {
      final updated = await ref.read(orderRepositoryProvider).cancelOrder(order.id);
      ref.invalidate(pastOrdersProvider);
      if (mounted) {
        setState(() => _order = updated);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Order cancelled')));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // This screen is seeded once from a static `Order` (via `extra` from the
    // list, or from `OrderDetailByIdScreen`'s one-time fetch) rather than
    // watching a provider directly, so it would otherwise never notice a
    // status change made elsewhere (the admin console). Listening here lets
    // it pick up whatever `NotificationService` invalidates — silently, no
    // loading spinner — without coupling this screen's initial render to a
    // fresh network round-trip.
    final initialOrder = widget.order;
    if (initialOrder != null) {
      ref.listen<AsyncValue<Order>>(orderByIdProvider(initialOrder.id), (previous, next) {
        next.whenData((updated) {
          if (mounted) setState(() => _order = updated);
        });
      });
    }

    final order = _order;
    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order')),
        body: const Center(child: Text('Order not found.')),
      );
    }

    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(order.orderNumber)),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Placed on ${DateFormat('d MMM yyyy').format(order.placedOn)}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              StatusChip(label: order.status.label, positive: order.status != OrderStatus.cancelled),
            ],
          ),
          const SizedBox(height: AppConstants.spacingLg),
          Text('Items', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppConstants.spacingSm),
          Card(
            child: Column(
              children: [
                for (final item in order.items)
                  ListTile(
                    title: Text(item.name),
                    subtitle: Text('Qty ${item.quantity} × ₹${item.price}'),
                    trailing: Text('₹${item.lineTotal}', style: theme.textTheme.titleSmall),
                  ),
                const Divider(height: 1),
                ListTile(
                  title: Text('Total', style: theme.textTheme.titleMedium),
                  trailing: Text('₹${order.total}', style: theme.textTheme.titleMedium),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          OutlinedButton.icon(
            onPressed: _downloadingInvoice ? null : _downloadInvoice,
            icon: _downloadingInvoice
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.download_outlined),
            label: const Text('Download invoice'),
          ),
          if (order.status.isCustomerCancellable) ...[
            const SizedBox(height: AppConstants.spacingSm),
            OutlinedButton.icon(
              onPressed: _cancelling ? null : _cancel,
              style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
              icon: _cancelling
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.cancel_outlined),
              label: const Text('Cancel order'),
            ),
          ],
        ],
      ),
    );
  }
}
