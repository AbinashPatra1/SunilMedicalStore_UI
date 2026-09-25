import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_client.dart';
import 'package:sunil_medical_store/features/admin/orders/data/api_admin_order_repository.dart';
import 'package:sunil_medical_store/features/admin/orders/domain/admin_order.dart';
import 'package:sunil_medical_store/features/admin/orders/domain/admin_order_repository.dart';
import 'package:sunil_medical_store/core/paging/paged.dart';

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

/// Admin orders matching the current filters, paged (numbered pages).
final adminOrdersProvider = AsyncNotifierProvider<AdminOrdersNotifier, PagedState<AdminOrder>>(AdminOrdersNotifier.new);

class AdminOrdersNotifier extends PagedNotifier<AdminOrder> {
  late OrderFilters _filters;

  @override
  int get pageSize => kAdminPageSize;

  @override
  Future<PagedState<AdminOrder>> build() {
    _filters = ref.watch(adminOrderFiltersProvider);
    return loadFirst();
  }

  @override
  Future<PageResult<AdminOrder>> fetch(int page) =>
      ref.read(adminOrderRepositoryProvider).listPage(_filters, page: page, pageSize: pageSize);

  @override
  Object keyOf(AdminOrder item) => item.id;
}

/// A single admin order for the detail/edit screen.
final adminOrderByIdProvider = FutureProvider.autoDispose.family<AdminOrder, String>((ref, id) {
  return ref.watch(adminOrderRepositoryProvider).getById(id);
});
