/// Fulfilment status of an order.
enum OrderStatus {
  created,
  processing,
  shipped,
  delivered,
  cancelled;

  String get label => switch (this) {
    OrderStatus.created => 'Created',
    OrderStatus.processing => 'Processing',
    OrderStatus.shipped => 'Shipped',
    OrderStatus.delivered => 'Delivered',
    OrderStatus.cancelled => 'Cancelled',
  };

  /// The customer can self-cancel only before the order ships.
  bool get isCustomerCancellable => this == created || this == processing;

  /// The next status in the linear pharmacy fulfilment flow — admin can
  /// only ever advance one step at a time (via a swipe action), never jump
  /// straight to an arbitrary status. `null` once there's no next step
  /// (already `delivered`, or `cancelled` — cancelling exits the flow).
  OrderStatus? get next => switch (this) {
    OrderStatus.created => OrderStatus.processing,
    OrderStatus.processing => OrderStatus.shipped,
    OrderStatus.shipped => OrderStatus.delivered,
    OrderStatus.delivered => null,
    OrderStatus.cancelled => null,
  };

  /// Swipe-bar label for advancing from this status to [next]. `null` when
  /// [next] is `null` (nothing to advance to).
  String? get advanceLabel => switch (this) {
    OrderStatus.created => 'Process Order',
    OrderStatus.processing => 'Mark as Shipped',
    OrderStatus.shipped => 'Mark as Delivered',
    OrderStatus.delivered => null,
    OrderStatus.cancelled => null,
  };
}

/// A single line item within an [Order].
class OrderItem {
  const OrderItem({required this.name, required this.quantity, required this.price});

  final String name;
  final int quantity;

  /// Unit price in rupees.
  final int price;

  int get lineTotal => quantity * price;
}

/// An order — placed via checkout, or read back as history.
///
/// Lives in `core/models` (not a single feature's `domain/`) because it's
/// created by the cart/checkout flow and read by the profile order-history
/// screens; both depend on this one shared shape.
class Order {
  const Order({
    required this.id,
    required this.orderNumber,
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
  final DateTime placedOn;
  final OrderStatus status;
  final List<OrderItem> items;

  /// Server-computed price breakdown, in rupees. Authoritative — not derived
  /// from [items] client-side, since discount/delivery can't be recovered
  /// from line items alone.
  final int subtotal;
  final int discount;
  final int delivery;
  final int total;

  /// Wire value of the payment method chosen at checkout (e.g. `googlePay`,
  /// `upi`, `cod`), when known.
  final String? paymentMethod;
  final String? addressId;

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);
}
