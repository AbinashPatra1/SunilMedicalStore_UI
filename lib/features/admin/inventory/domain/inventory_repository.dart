import 'package:sunil_medical_store/features/medicines/domain/product.dart';

/// Admin-side view of the product catalog: list-all (including out of stock),
/// read-one, create, update, and delete.
///
/// The customer-facing `ProductRepository` also reads products, but from a
/// different endpoint that hides administrative fields — kept separate so
/// that reads/writes evolve independently.
abstract interface class InventoryRepository {
  /// All products in the catalog, optionally filtered to a category label.
  /// Out-of-stock items are included so admins can restock them.
  Future<List<Product>> list({String? category});

  /// Single product by id.
  Future<Product> getById(String id);

  /// Creates a new product. Returns the server-assigned id/state.
  Future<Product> create(ProductInput input);

  /// Updates an existing product. Returns the refreshed product.
  Future<Product> update(String id, ProductInput input);

  Future<void> delete(String id);
}

/// Value object for create/update requests. Server assigns [Product.id]
/// on create; the client never sets it.
class ProductInput {
  const ProductInput({
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    required this.stock,
    required this.requiresPrescription,
    this.composition,
    this.mrp,
    this.description = '',
    this.dosage,
    this.ingredients = const [],
    this.imageUrl,
  });

  final String name;
  final String brand;
  final String category;
  final int price;
  final int stock;
  final bool requiresPrescription;
  final String? composition;
  final int? mrp;
  final String description;
  final String? dosage;
  final List<String> ingredients;
  final String? imageUrl;
}
