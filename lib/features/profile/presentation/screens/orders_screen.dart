import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/routes/app_routes.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/profile/domain/order.dart';
import 'package:sunil_medical_store/features/profile/presentation/providers/profile_providers.dart';
import 'package:sunil_medical_store/features/profile/presentation/widgets/status_chip.dart';

/// Profile > Orders: the customer's order history. Tapping an order opens its
/// detail screen.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(pastOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Could not load orders.')),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(child: Text('No orders yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppConstants.spacingLg),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppConstants.spacingMd),
            itemBuilder: (context, index) {
              final order = orders[index];
              return _OrderCard(
                order: order,
                onTap: () => context.push(AppRoutes.profileOrderDetail, extra: order),
              );
            },
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(order.orderNumber, style: theme.textTheme.titleSmall)),
                  StatusChip(label: order.status.label, positive: order.status != OrderStatus.cancelled),
                ],
              ),
              const SizedBox(height: AppConstants.spacingXs),
              Text(
                '${DateFormat('d MMM yyyy').format(order.placedOn)} • ${order.itemCount} item(s)',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Row(
                children: [
                  Text('₹${order.total}', style: theme.textTheme.titleSmall),
                  const Spacer(),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
