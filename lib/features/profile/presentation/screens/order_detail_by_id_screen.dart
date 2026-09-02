import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/features/profile/presentation/providers/profile_providers.dart';
import 'package:sunil_medical_store/features/profile/presentation/screens/order_detail_screen.dart';

/// Fetches an order by id, then delegates to [OrderDetailScreen]. Only
/// reachable from a push-notification tap — the in-list route passes the
/// already-loaded `Order` via `extra` instead, so it stays on
/// [OrderDetailScreen] directly.
class OrderDetailByIdScreen extends ConsumerWidget {
  const OrderDetailByIdScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(orderByIdProvider(orderId));
    return async.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Order')),
        body: Center(
          child: Text(error is ApiException ? error.message : 'Could not load order.'),
        ),
      ),
      data: (order) => OrderDetailScreen(order: order),
    );
  }
}
