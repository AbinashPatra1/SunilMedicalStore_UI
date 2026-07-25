import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/profile/domain/order.dart';
import 'package:sunil_medical_store/features/profile/presentation/widgets/status_chip.dart';

/// Detail of a single order, with a (placeholder) download-invoice action.
class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.order});

  final Order? order;

  @override
  Widget build(BuildContext context) {
    final order = this.order;
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
            onPressed: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(content: Text('Invoice download coming soon')));
            },
            icon: const Icon(Icons.download_outlined),
            label: const Text('Download invoice'),
          ),
        ],
      ),
    );
  }
}
