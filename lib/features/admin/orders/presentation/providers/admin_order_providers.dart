import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_client.dart';
import 'package:sunil_medical_store/features/admin/orders/data/api_admin_order_repository.dart';
import 'package:sunil_medical_store/features/admin/orders/domain/admin_order.dart';
import 'package:sunil_medical_store/features/admin/orders/domain/admin_order_repository.dart';

final adminOrderRepositoryProvider = Provider<AdminOrderRepository>((ref) {
  return ApiAdminOrderRepository(ref.watch(dioProvider));
});

/// Currently-applied filters for the admin orders list. Updated by the
/// filter UI in the list screen; [adminOrdersProvider] rebuilds when it
/// changes.
final adminOrderFiltersProvider =
    NotifierProvider<AdminOrderFiltersNotifier, OrderFilters>(AdminOrderFiltersNotifier.new);

class AdminOrderFiltersNotifier extends Notifier<OrderFilters> {
  @override
  OrderFilters build() => const OrderFilters();

  void set(OrderFilters next) => state = next;
}

/// Admin orders matching the current filters.
final adminOrdersProvider = FutureProvider<List<AdminOrder>>((ref) {
  final filters = ref.watch(adminOrderFiltersProvider);
  return ref.watch(adminOrderRepositoryProvider).list(filters);
});

/// A single admin order for the detail/edit screen.
final adminOrderByIdProvider = FutureProvider.family<AdminOrder, String>((ref, id) {
  return ref.watch(adminOrderRepositoryProvider).getById(id);
});
