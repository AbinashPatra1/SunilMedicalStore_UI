import 'package:sunil_medical_store/core/models/order.dart';
import 'package:sunil_medical_store/features/admin/orders/domain/admin_order.dart';

/// Query filters for [AdminOrderRepository.list]. Any field left null means
/// "don't filter on this dimension".
class OrderFilters {
  const OrderFilters({this.search, this.status, this.dateFrom, this.dateTo});

  /// Free-text match against order number, user name and phone (server-side).
  final String? search;
  final OrderStatus? status;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  bool get isEmpty =>
      (search == null || search!.isEmpty) && status == null && dateFrom == null && dateTo == null;
}

/// Admin's read + write surface for orders across all users.
abstract interface class AdminOrderRepository {
  /// All orders matching [filters], newest first.
  Future<List<AdminOrder>> list(OrderFilters filters);

  /// Single order by id.
  Future<AdminOrder> getById(String id);

  /// Changes an order's status (e.g. advance to `shipped`/`delivered`, or
  /// cancel). Admin can set any status, including `cancelled`, regardless of
  /// the customer-cancellable window that applies to self-service cancels.
  Future<AdminOrder> updateStatus(String id, OrderStatus status);
}
