import 'package:sunil_medical_store/core/models/order.dart';
import 'package:sunil_medical_store/features/cart/domain/cart_item.dart';
import 'package:sunil_medical_store/features/cart/domain/razorpay_order_details.dart';

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
  /// `upi`, `cod`, `razorpay`). When [paymentMethod] is `razorpay`, also pass
  /// the checkout result from [createRazorpayOrder] + the Razorpay SDK
  /// (`razorpayOrderId`/`razorpayPaymentId`/`razorpaySignature`) — the
  /// backend verifies the signature before creating the order.
  Future<Order> placeOrder({
    required List<OrderRequestItem> items,
    required String addressId,
    String? promoCode,
    required String paymentMethod,
    String? prescriptionId,
    String? razorpayOrderId,
    String? razorpayPaymentId,
    String? razorpaySignature,
  });

  /// Creates a Razorpay order for [items] priced the same authoritative way
  /// [placeOrder] would — call this first when paying online, open Razorpay
  /// checkout with the result, then call [placeOrder] with the checkout's
  /// success response. See `docs/API_ENDPOINTS.md` #80.
  Future<RazorpayOrderDetails> createRazorpayOrder({
    required List<OrderRequestItem> items,
    required String addressId,
    String? promoCode,
  });

  /// Cancels the caller's own order. Only valid while
  /// `order.status.isCustomerCancellable` — the server rejects it once the
  /// order has shipped. Automatically refunds a captured Razorpay payment,
  /// if there was one (see `docs/API_ENDPOINTS.md` #45).
  Future<Order> cancelOrder(String id);

  /// Asks to return [lines] (product id + quantity) of a delivered order,
  /// for [reason]. The order moves to `returnRequested` until the admin
  /// decides — see `docs/API_ENDPOINTS.md` #87.
  Future<Order> requestReturn(String id, {required List<ReturnLine> lines, required String reason});
}
