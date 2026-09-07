import 'package:sunil_medical_store/core/models/order.dart';
import 'package:sunil_medical_store/features/cart/domain/cart_item.dart';

/// One line of a [OrderRepository.placeOrder] request — a catalog reference
/// and quantity, **not** a price. The server prices authoritatively from its
/// own catalog data; the client never sends prices at checkout.
class OrderRequestItem {
  const OrderRequestItem({
    required this.kind,
    required this.catalogId,
    required this.quantity,
    this.scheduledDate,
    this.timeSlot,
  });

  final CartItemKind kind;
  final String catalogId;
  final int quantity;

  /// Sample-collection date/time window, only set when [kind] is [CartItemKind.labTest].
  final DateTime? scheduledDate;
  final String? timeSlot;
}

/// Places orders, implemented by the data layer.
abstract interface class OrderRepository {
  /// Places an order for [items] and returns the server-priced [Order]
  /// (subtotal/discount/delivery/total are computed server-side).
  ///
  /// [paymentMethod] is the wire value (`googlePay`, `phonePe`, `bhim`,
  /// `upi`, `cod`); pass [upiId] when [paymentMethod] is `upi`.
  Future<Order> placeOrder({
    required List<OrderRequestItem> items,
    required String addressId,
    String? promoCode,
    required String paymentMethod,
    String? upiId,
    String? prescriptionId,
  });

  /// Cancels the caller's own order. Only valid while
  /// `order.status.isCustomerCancellable` — the server rejects it once the
  /// order has shipped.
  Future<Order> cancelOrder(String id);
}
