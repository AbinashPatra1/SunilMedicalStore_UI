/// Fulfilment status of an order.
enum OrderStatus {
  created,
  processing,
  shipped,
  delivered,
  cancelled,
  returnRequested,
  returned;

  /// Parses the wire value; unknown values fall back to [created] so a new
  /// backend status never crashes an order list.
  static OrderStatus fromWire(String? value) {
    for (final s in values) {
      if (s.name == value) return s;
    }
    return OrderStatus.created;
  }

  String get label => switch (this) {
    OrderStatus.created => 'Created',
    OrderStatus.processing => 'Processing',
    OrderStatus.shipped => 'Shipped',
    OrderStatus.delivered => 'Delivered',
    OrderStatus.cancelled => 'Cancelled',
    OrderStatus.returnRequested => 'Return requested',
    OrderStatus.returned => 'Returned',
  };

  /// The customer can self-cancel until the order ships (`created` or
  /// `processing`).
  bool get isCustomerCancellable => this == created || this == processing;

  /// Admin can cancel at any point until the order is delivered.
  bool get isAdminCancellable => this == created || this == processing || this == shipped;

  /// The next status in the linear pharmacy fulfilment flow — admin can
  /// only ever advance one step at a time (via a swipe action), never jump
  /// straight to an arbitrary status. `null` once there's no next step
  /// (already `delivered`, or `cancelled` — cancelling exits the flow).
  OrderStatus? get next => switch (this) {
    OrderStatus.created => OrderStatus.processing,
    OrderStatus.processing => OrderStatus.shipped,
    OrderStatus.shipped => OrderStatus.delivered,
    _ => null,
  };

  /// Swipe-bar label for advancing from this status to [next]. `null` when
  /// [next] is `null` (nothing to advance to).
  String? get advanceLabel => switch (this) {
    OrderStatus.created => 'Process Order',
    OrderStatus.processing => 'Mark as Shipped',
    OrderStatus.shipped => 'Mark as Delivered',
    _ => null,
  };
}

/// Outcome of an automatic refund (backlog #20) — only set when an order
/// paid via Razorpay is later cancelled. `null` on [Order.refundStatus]
/// means either no refund applies (COD, or never cancelled) or the order
/// predates this feature.
enum RefundStatus {
  pending,
  processed,
  failed;

  /// Parses the wire value; `null` (or anything unrecognized) means no refund.
  static RefundStatus? fromWire(String? value) {
    for (final s in values) {
      if (s.name == value) return s;
    }
    return null;
  }

  String get label => switch (this) {
    RefundStatus.pending => 'Refund in progress',
    RefundStatus.processed => 'Refunded',
    RefundStatus.failed => 'Refund failed — contact support',
  };
}

/// One entry of an order's status history: it moved to [status] at [at].
class OrderStatusEvent {
  const OrderStatusEvent(this.status, this.at);

  final OrderStatus status;
  final DateTime at;

  /// Parses `[{status, at}]`; malformed entries are skipped.
  static List<OrderStatusEvent> listFromJson(Object? raw) {
    final events = <OrderStatusEvent>[];
    for (final e in (raw as List?) ?? const []) {
      if (e is! Map) continue;
      final at = DateTime.tryParse(e['at'] as String? ?? '');
      if (at == null) continue;
      events.add(OrderStatusEvent(OrderStatus.fromWire(e['status'] as String?), at));
    }
    events.sort((a, b) => a.at.compareTo(b.at));
    return events;
  }
}

/// A product line the customer asked to return, and how many units.
class ReturnLine {
  const ReturnLine({required this.productId, required this.name, required this.quantity});

  final String productId;
  final String name;
  final int quantity;
}

/// A customer's return request on an order (backlog #25).
class OrderReturn {
  const OrderReturn({
    required this.lines,
    required this.reason,
    this.requestedOn,
    this.decision,
    this.decisionNote,
  });

  final List<ReturnLine> lines;
  final String reason;
  final DateTime? requestedOn;

  /// `null` while pending, else `approved` / `rejected`.
  final String? decision;
  final String? decisionNote;

  bool get isRejected => decision == 'rejected';

  static OrderReturn? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final lines = <ReturnLine>[
      for (final l in (raw['items'] as List?) ?? const [])
        if (l is Map && l['productId'] is String)
          ReturnLine(
            productId: l['productId'] as String,
            name: (l['name'] as String?) ?? '',
            quantity: (l['quantity'] as int?) ?? 1,
          ),
    ];
    return OrderReturn(
      lines: lines,
      reason: (raw['reason'] as String?) ?? '',
      requestedOn: DateTime.tryParse(raw['requestedOn'] as String? ?? ''),
      decision: raw['decision'] as String?,
      decisionNote: raw['decisionNote'] as String?,
    );
  }
}

/// A single line item within an [Order].
class OrderItem {
  const OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
    this.productId,
    this.kind,
  });

  final String name;
  final int quantity;

  /// Unit price in rupees.
  final int price;

  /// Catalog id of the medicine (needed to reorder it) — `null` until the
  /// backend returns it (`docs/API_ENDPOINTS.md` §Orders).
  final String? productId;

  /// `medicine` or `labTest`, when the backend says which.
  final String? kind;

  bool get isLabTest => kind == 'labTest';

  int get lineTotal => quantity * price;

  static OrderItem fromJson(Map<String, dynamic> json) => OrderItem(
    name: json['name'] as String,
    quantity: json['quantity'] as int,
    price: json['price'] as int,
    productId: json['productId'] as String?,
    kind: json['kind'] as String?,
  );

  static List<OrderItem> listFromJson(Object? raw) =>
      ((raw as List?) ?? const []).cast<Map<String, dynamic>>().map(fromJson).toList();
}

/// The delivery address as it was when the order was placed, kept as one
/// display string — the order screens never edit it.
class OrderAddress {
  const OrderAddress(this.formatted);

  final String formatted;

  /// Accepts either a ready-made string or an object with
  /// `line1`/`line2`/`area`/`city`/`state`/`pincode`; `null` for anything else.
  static OrderAddress? tryParse(Object? raw) {
    if (raw is String) return raw.trim().isEmpty ? null : OrderAddress(raw.trim());
    if (raw is Map) {
      String? s(String key) {
        final v = raw[key];
        return v is String && v.trim().isNotEmpty ? v.trim() : null;
      }

      final cityLine = [s('city'), [s('state'), s('pincode')].whereType<String>().join(' ')]
          .whereType<String>()
          .where((p) => p.isNotEmpty)
          .join(', ');
      final parts = [s('line1'), s('line2'), s('area'), cityLine].whereType<String>().where((p) => p.isNotEmpty);
      return parts.isEmpty ? null : OrderAddress(parts.join(', '));
    }
    return null;
  }
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
    this.refundStatus,
    this.platformFee = 0,
    this.deliveredOn,
    this.deliveryAddress,
    this.statusHistory = const [],
    this.returnRequest,
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

  /// Flat platform fee charged on pharmacy orders (`0` when none/waived).
  final int platformFee;
  final int total;

  /// When the order was marked delivered, once it is (`null` before that, or
  /// until the backend returns it).
  final DateTime? deliveredOn;

  /// Delivery address snapshot from when the order was placed, if the backend
  /// returns one.
  final OrderAddress? deliveryAddress;

  /// When each status was reached, oldest first (empty until the backend
  /// returns it).
  final List<OrderStatusEvent> statusHistory;

  /// The customer's return request, once one exists.
  final OrderReturn? returnRequest;

  /// Wire value of the payment method chosen at checkout (e.g. `googlePay`,
  /// `upi`, `cod`), when known.
  final String? paymentMethod;
  final String? addressId;

  /// Automatic-refund outcome (backlog #20) — see [RefundStatus].
  final RefundStatus? refundStatus;

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);
}
