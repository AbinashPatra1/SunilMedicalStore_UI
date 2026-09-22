import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/widgets/app_card.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/models/order.dart';
import 'package:sunil_medical_store/core/theme/app_colors.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/core/utils/order_policy.dart';
import 'package:sunil_medical_store/core/utils/support_contact.dart';
import 'package:sunil_medical_store/features/admin/delivery/domain/delivery_settings.dart';
import 'package:sunil_medical_store/features/profile/presentation/widgets/status_chip.dart';

/// Building blocks shared by the customer's and the admin's order detail
/// screens, so both read the same way.

String paymentMethodLabel(String? wire) => switch (wire) {
  'razorpay' => 'Paid online (Razorpay)',
  'cod' => 'Cash on Delivery',
  'googlePay' => 'Google Pay',
  'phonePe' => 'PhonePe',
  'bhim' => 'BHIM',
  'upi' => 'UPI',
  _ => 'Not available',
};

final _dateFormat = DateFormat('d MMM yyyy');

/// Top card: status pill + placed/delivered date, the progress bar, and an
/// optional [action] (the customer's Reorder button).
class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({
    super.key,
    required this.status,
    required this.placedOn,
    required this.deliveredOn,
    this.action,
  });

  final OrderStatus status;
  final DateTime placedOn;
  final DateTime? deliveredOn;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showDelivered =
        status == OrderStatus.delivered && deliveredOn != null;
    final dateText = showDelivered
        ? 'Delivered on ${_dateFormat.format(deliveredOn!.toLocal())}'
        : 'Placed on ${_dateFormat.format(placedOn.toLocal())}';

    return AppCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                StatusChip(
                  label: status.label,
                  positive: status != OrderStatus.cancelled,
                ),
                const SizedBox(width: AppConstants.spacingMd),
                Expanded(
                  child: Text(
                    dateText,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingLg),
            OrderProgressBar(status: status),
            if (action != null) ...[
              const SizedBox(height: AppConstants.spacingLg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Three-point progress bar: Created → Processed → Delivered. "Shipped" sits
/// between the last two. A cancelled order shows the bar in the error color.
class OrderProgressBar extends StatelessWidget {
  const OrderProgressBar({super.key, required this.status});

  final OrderStatus status;

  static const _nodeSize = 22.0;
  static const _trackHeight = 8.0;
  static const _labels = ['Created', 'Processed', 'Delivered'];
  static const _nodeFractions = [0.0, 0.5, 1.0];

  double get _fraction => switch (status) {
    OrderStatus.created || OrderStatus.cancelled => 0.0,
    OrderStatus.processing => 0.5,
    OrderStatus.shipped => 0.75,
    OrderStatus.delivered => 1.0,
  };

  /// Amber at the start, teal in the middle, green at the end.
  static Color _colorAt(double f) => f <= 0.5
      ? Color.lerp(const Color(0xFFF9A825), AppColors.primary, f / 0.5)!
      : Color.lerp(
          AppColors.primary,
          const Color(0xFF2E7D32),
          (f - 0.5) / 0.5,
        )!;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cancelled = status == OrderStatus.cancelled;
    final fraction = _fraction;

    Color nodeColor(int i) =>
        cancelled ? theme.colorScheme.error : _colorAt(_nodeFractions[i]);

    return Semantics(
      label: 'Order progress: ${status.label}',
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth - _nodeSize;
              final fillWidth = trackWidth * fraction;
              final fillEnd = cancelled
                  ? theme.colorScheme.error
                  : _colorAt(fraction);
              final fillStart = cancelled
                  ? theme.colorScheme.error
                  : _colorAt(0);
              return SizedBox(
                height: _nodeSize,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Positioned(
                      left: _nodeSize / 2,
                      width: trackWidth,
                      child: Container(
                        height: _trackHeight,
                        decoration: BoxDecoration(
                          color: cancelled
                              ? theme.colorScheme.errorContainer
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusFull,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: _nodeSize / 2,
                      width: fillWidth,
                      child: Container(
                        height: _trackHeight,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [fillStart, fillEnd],
                          ),
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusFull,
                          ),
                        ),
                      ),
                    ),
                    for (var i = 0; i < 3; i++)
                      Positioned(
                        left: trackWidth * _nodeFractions[i],
                        child: _Node(
                          reached: fraction >= _nodeFractions[i],
                          color: nodeColor(i),
                          cancelled: cancelled && i == 0,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 3; i++)
                Text(
                  cancelled && i == 0 ? 'Cancelled' : _labels[i],
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: fraction >= _nodeFractions[i]
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: fraction >= _nodeFractions[i]
                        ? (cancelled
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurface)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({
    required this.reached,
    required this.color,
    required this.cancelled,
  });

  final bool reached;
  final Color color;
  final bool cancelled;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Container(
      width: OrderProgressBar._nodeSize,
      height: OrderProgressBar._nodeSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: reached ? color : surface,
        border: Border.all(
          color: reached
              ? color
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: reached
          ? Icon(
              cancelled ? Icons.close : Icons.check,
              size: 14,
              color: Colors.white,
            )
          : null,
    );
  }
}

/// The order's items followed by the full cost breakdown and payment method.
class OrderItemsBillCard extends StatelessWidget {
  const OrderItemsBillCard({
    super.key,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.delivery,
    required this.platformFee,
    required this.total,
    required this.paymentMethod,
  });

  final List<OrderItem> items;
  final int subtotal;
  final int discount;
  final int delivery;
  final int platformFee;
  final int total;
  final String? paymentMethod;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final free = theme.textTheme.bodyMedium?.copyWith(
      color: AppColors.success,
      fontWeight: FontWeight.w700,
    );

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final item in items)
            ListTile(
              title: Text(item.name),
              subtitle: Text('Qty ${item.quantity} × ₹${item.price}'),
              trailing: Text(
                '₹${item.lineTotal}',
                style: theme.textTheme.titleSmall,
              ),
            ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingLg),
            child: Column(
              children: [
                _BillRow(label: 'Subtotal', value: '₹$subtotal'),
                if (discount > 0)
                  _BillRow(
                    label: 'Discount',
                    value: '−₹$discount',
                    valueStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                _BillRow(
                  label: 'Delivery',
                  value: delivery == 0 ? 'Free' : '₹$delivery',
                  valueStyle: delivery == 0 ? free : null,
                ),
                if (platformFee > 0)
                  _BillRow(label: 'Platform fee', value: '₹$platformFee'),
                const Divider(height: AppConstants.spacingXl),
                _BillRow(
                  label: 'Total',
                  value: '₹$total',
                  labelStyle: theme.textTheme.titleMedium,
                  valueStyle: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.payments_outlined),
            title: const Text('Payment method'),
            subtitle: Text(paymentMethodLabel(paymentMethod)),
          ),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow({
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: labelStyle ?? base),
          Text(value, style: valueStyle ?? base),
        ],
      ),
    );
  }
}

/// Cancellation note + return-window message, and (customer only) a
/// "Need help?" line that opens the store's WhatsApp.
class OrderPolicySection extends StatelessWidget {
  const OrderPolicySection({
    super.key,
    required this.order,
    required this.settings,
    this.showHelp = false,
    this.showCancelNote = true,
  });

  final OrderPolicyInput order;
  final DeliverySettings? settings;
  final bool showHelp;

  /// The customer-facing cancel rule; the admin view hides it, since admins
  /// can cancel at any point.
  final bool showCancelNote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cancelNote = showCancelNote
        ? cancelPolicyMessage(order.status)
        : null;
    final returnInfo = evaluateReturn(
      status: order.status,
      deliveredOn: order.deliveredOn,
      returnsEnabled: settings?.returnsEnabled ?? false,
      windowDays:
          settings?.returnWindowDays ??
          DeliverySettings.defaultReturnWindowDays,
    );
    final returnNote = switch (returnInfo.state) {
      ReturnState.hidden => null,
      ReturnState.notStarted =>
        'Returns are accepted within ${returnInfo.days} days of delivery.',
      ReturnState.open =>
        'This order can be returned by ${_dateFormat.format(returnInfo.date!)}.',
      ReturnState.closed =>
        'The return window closed on ${_dateFormat.format(returnInfo.date!)}.',
    };
    if (cancelNote == null && returnNote == null && !showHelp)
      return const SizedBox.shrink();

    return AppCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cancelNote != null)
              _NoteRow(icon: Icons.cancel_outlined, text: cancelNote),
            if (returnNote != null)
              _NoteRow(
                icon: Icons.assignment_return_outlined,
                text: returnNote,
              ),
            if (showHelp) ...[
              if (cancelNote != null || returnNote != null)
                const Divider(height: AppConstants.spacingXl),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Need help with an order? ',
                    style: theme.textTheme.bodyMedium,
                  ),
                  GestureDetector(
                    onTap: () => openSupportWhatsApp(
                      context,
                      message:
                          'Hi, I need help with order ${order.orderNumber}.',
                    ),
                    child: Text(
                      'Contact us',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The few order fields [OrderPolicySection] needs — lets the customer's
/// `Order` and the admin's `AdminOrder` share it.
class OrderPolicyInput {
  const OrderPolicyInput({
    required this.status,
    required this.deliveredOn,
    required this.orderNumber,
  });

  final OrderStatus status;
  final DateTime? deliveredOn;
  final String orderNumber;
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

/// Delivery address, order id and order date, stacked vertically.
class OrderInfoCard extends StatelessWidget {
  const OrderInfoCard({
    super.key,
    required this.address,
    required this.orderNumber,
    required this.placedOn,
  });

  final String? address;
  final String orderNumber;
  final DateTime placedOn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget block(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );

    return AppCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.spacingLg,
          AppConstants.spacingLg,
          AppConstants.spacingLg,
          AppConstants.spacingSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order information', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppConstants.spacingMd),
            block('Delivery address', address ?? 'Not available'),
            block('Order ID', orderNumber),
            block(
              'Order date',
              DateFormat('d MMM yyyy, h:mm a').format(placedOn.toLocal()),
            ),
          ],
        ),
      ),
    );
  }
}
