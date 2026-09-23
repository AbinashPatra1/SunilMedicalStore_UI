import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/routes/app_routes.dart';
import 'package:sunil_medical_store/core/utils/order_policy.dart';
import 'package:sunil_medical_store/core/theme/app_palette.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/core/widgets/refund_status_banner.dart';
import 'package:sunil_medical_store/core/models/order.dart';
import 'package:sunil_medical_store/features/admin/delivery/domain/delivery_settings.dart';
import 'package:sunil_medical_store/features/admin/delivery/presentation/providers/delivery_settings_providers.dart';
import 'package:sunil_medical_store/features/cart/presentation/providers/cart_providers.dart';
import 'package:sunil_medical_store/features/cart/presentation/providers/reorder.dart';
import 'package:sunil_medical_store/features/profile/presentation/providers/address_controller.dart';
import 'package:sunil_medical_store/features/profile/presentation/providers/profile_providers.dart';
import 'package:sunil_medical_store/features/profile/presentation/widgets/order_detail_sections.dart';
import 'package:url_launcher/url_launcher.dart';

/// Detail of a single order, with a download-invoice action and — while the
/// order is still cancellable — a Cancel action.
class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.order});

  final Order? order;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

/// A delivered order can be returned while the store's return window is
/// still open — and only if it has medicine lines the backend identified.
bool _canReturn(Order order, DeliverySettings? settings) {
  if (order.status != OrderStatus.delivered) return false;
  if (!order.items.any((i) => !i.isLabTest && i.productId != null)) return false;
  return evaluateReturn(
        status: order.status,
        deliveredOn: order.deliveredOn,
        returnsEnabled: settings?.returnsEnabled ?? false,
        windowDays: settings?.returnWindowDays ?? DeliverySettings.defaultReturnWindowDays,
      ).state ==
      ReturnState.open;
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  late Order? _order = widget.order;
  bool _cancelling = false;
  bool _downloadingInvoice = false;
  bool _reordering = false;

  Future<void> _downloadInvoice() async {
    final order = _order;
    if (order == null) return;
    setState(() => _downloadingInvoice = true);
    try {
      final url = await ref
          .read(profileRepositoryProvider)
          .orderInvoiceUrl(order.id);
      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Could not open the invoice.')),
          );
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

  Future<void> _reorder() async {
    final order = _order;
    if (order == null) return;
    setState(() => _reordering = true);
    try {
      final result = await reorder(ref, order);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(result.message)));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _reordering = false);
    }
  }

  Future<void> _return() async {
    final order = _order;
    if (order == null) return;
    final updated = await context.push<Order>(AppRoutes.profileOrderReturn, extra: order);
    if (updated != null && mounted) setState(() => _order = updated);
  }

  Future<void> _cancel() async {
    final order = _order;
    if (order == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel order?'),
        content: Text(
          'This will cancel order ${order.orderNumber}. This can\'t be undone.',
        ),
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
      final updated = await ref
          .read(orderRepositoryProvider)
          .cancelOrder(order.id);
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
      ref.listen<AsyncValue<Order>>(orderByIdProvider(initialOrder.id), (
        previous,
        next,
      ) {
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
    final settings = ref.watch(deliverySettingsProvider).value;
    String? address = order.deliveryAddress?.formatted;
    if (address == null) {
      for (final a in ref.watch(addressesProvider).value ?? const []) {
        if (a.id == order.addressId) address = a.formatted;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(order.orderNumber)),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        children: [
          OrderSummaryCard(
            status: order.status,
            placedOn: order.placedOn,
            deliveredOn: order.deliveredOn,
            action: canReorder(order)
                ? FilledButton.tonalIcon(
                    style: AppPalette.cartActionButtonStyle(context),
                    onPressed: _reordering ? null : _reorder,
                    icon: _reordering
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.replay),
                    label: const Text('Reorder'),
                  )
                : null,
          ),
          if (order.refundStatus != null) ...[
            const SizedBox(height: AppConstants.spacingMd),
            RefundStatusBanner(status: order.refundStatus!),
          ],
          const SizedBox(height: AppConstants.spacingLg),
          Text('Items', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppConstants.spacingSm),
          OrderItemsBillCard(
            items: order.items,
            subtotal: order.subtotal,
            discount: order.discount,
            delivery: order.delivery,
            platformFee: order.platformFee,
            total: order.total,
            paymentMethod: order.paymentMethod,
          ),
          const SizedBox(height: AppConstants.spacingLg),
          OutlinedButton.icon(
            onPressed: _downloadingInvoice ? null : _downloadInvoice,
            icon: _downloadingInvoice
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_outlined),
            label: const Text('Download invoice'),
          ),
          if (order.status.isCustomerCancellable) ...[
            const SizedBox(height: AppConstants.spacingSm),
            OutlinedButton.icon(
              onPressed: _cancelling ? null : _cancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              icon: _cancelling
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cancel_outlined),
              label: const Text('Cancel order'),
            ),
          ],
          if (_canReturn(order, settings)) ...[
            const SizedBox(height: AppConstants.spacingSm),
            OutlinedButton.icon(
              onPressed: _return,
              icon: const Icon(Icons.assignment_return_outlined),
              label: const Text('Return items'),
            ),
          ],
          if (order.returnRequest != null) ...[
            const SizedBox(height: AppConstants.spacingLg),
            OrderReturnCard(request: order.returnRequest!, status: order.status),
          ],
          const SizedBox(height: AppConstants.spacingLg),
          OrderPolicySection(
            order: OrderPolicyInput(
              status: order.status,
              deliveredOn: order.deliveredOn,
              orderNumber: order.orderNumber,
            ),
            settings: settings,
            showHelp: true,
          ),
          const SizedBox(height: AppConstants.spacingLg),
          OrderInfoCard(
            address: address,
            orderNumber: order.orderNumber,
            placedOn: order.placedOn,
          ),
        ],
      ),
    );
  }
}
