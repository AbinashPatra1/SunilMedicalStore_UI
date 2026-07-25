/// Fulfilment status of an order.
enum OrderStatus {
  delivered,
  processing,
  cancelled;

  String get label => switch (this) {
    OrderStatus.delivered => 'Delivered',
    OrderStatus.processing => 'Processing',
    OrderStatus.cancelled => 'Cancelled',
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

/// A past order placed by the customer.
class Order {
  const Order({
    required this.id,
    required this.orderNumber,
    required this.placedOn,
    required this.status,
    required this.items,
  });

  final String id;
  final String orderNumber;
  final DateTime placedOn;
  final OrderStatus status;
  final List<OrderItem> items;

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);
  int get total => items.fold(0, (sum, i) => sum + i.lineTotal);
}
