/// A sellable product in the pharmacy catalog.
///
/// Plain domain model; the data layer maps its own DTOs into this type.
/// [composition], [dosage] and [ingredients] are optional because they don't
/// apply to every category (e.g. devices have none).
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    this.mrp,
    this.requiresPrescription = false,
    this.description = '',
    this.composition,
    this.dosage,
    this.ingredients = const [],
    this.imageUrl,
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

  /// One-line marketing/usage description.
  final String description;

  /// Active composition, e.g. `Paracetamol 500mg` (`null` for non-medicines).
  final String? composition;

  /// How to take it, e.g. `1 tablet twice a day` (`null` when not applicable).
  final String? dosage;

  /// Key ingredients (empty when not applicable).
  final List<String> ingredients;

  /// Product photo URL, when the catalog has one (`null` falls back to a
  /// placeholder icon in the UI — no real product images exist yet).
  final String? imageUrl;

  /// Discount percentage vs. [mrp], or `null` when there's no discount.
  int? get discountPercent {
    final m = mrp;
    if (m == null || m <= price) return null;
    return (((m - price) / m) * 100).round();
  }
}
