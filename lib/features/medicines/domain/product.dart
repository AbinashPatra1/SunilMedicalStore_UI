/// A sellable product in the pharmacy catalog.
///
/// Plain domain model; the data layer maps its own DTOs into this type.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    this.mrp,
    this.requiresPrescription = false,
  });

  final String id;
  final String name;
  final String brand;

  /// Category label this product belongs to (matches a dashboard category).
  final String category;

  /// Selling price in rupees.
  final int price;

  /// Maximum retail price in rupees, when discounted (`null` if not).
  final int? mrp;

  /// Whether a valid prescription is required to buy this product.
  final bool requiresPrescription;

  /// Discount percentage vs. [mrp], or `null` when there's no discount.
  int? get discountPercent {
    final m = mrp;
    if (m == null || m <= price) return null;
    return (((m - price) / m) * 100).round();
  }
}
