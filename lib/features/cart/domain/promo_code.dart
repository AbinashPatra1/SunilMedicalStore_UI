/// How a [PromoCode] reduces the order total.
enum PromoType { percentage, flat }

/// A discount code that can be applied to the cart.
class PromoCode {
  const PromoCode({
    required this.code,
    required this.label,
    required this.type,
    required this.value,
    this.minOrder = 0,
  });

  final String code;

  /// Human-readable summary, e.g. `10% off`.
  final String label;
  final PromoType type;

  /// Percent (for [PromoType.percentage]) or rupees (for [PromoType.flat]).
  final int value;

  /// Minimum subtotal (rupees) required to use the code.
  final int minOrder;

  /// Discount in rupees for the given [subtotal], never more than the subtotal.
  int discountFor(int subtotal) {
    final raw = type == PromoType.percentage ? (subtotal * value ~/ 100) : value;
    return raw.clamp(0, subtotal);
  }
}
