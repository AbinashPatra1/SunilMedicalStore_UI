import 'package:sunil_medical_store/core/models/order.dart';

/// Admin's view of an order: everything [Order] carries, plus which user
/// placed it. Kept as a separate class (not a subclass) because the
/// customer's `Order` never has user info — server sends a different DTO to
/// the admin endpoints (mirrors the `AdminAppointment` / `PastAppointment` split).
class AdminOrder {
  const AdminOrder({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.placedOn,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.delivery,
    required this.total,
    this.paymentMethod,
    this.addressId,
  });

  final String id;
  final String orderNumber;

  final String userId;
  final String userName;

  /// National 10-digit number.
  final String userPhone;

  final DateTime placedOn;
  final OrderStatus status;
  final List<OrderItem> items;

  final int subtotal;
  final int discount;
  final int delivery;
  final int total;

  final String? paymentMethod;
  final String? addressId;

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);
}
