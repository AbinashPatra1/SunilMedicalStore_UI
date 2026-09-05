import 'package:sunil_medical_store/features/medicines/domain/product.dart';

/// Contract for reading the product catalog, implemented by the data layer.
///
/// Kept as an interface so the mock can later be swapped for a real
/// backend-backed implementation without touching providers or widgets.
abstract interface class ProductRepository {
  /// A curated set of products suggested to the customer on the home page.
  Future<List<Product>> suggestedProducts();

  /// Every product in the catalog.
  Future<List<Product>> allProducts();

  /// Products belonging to [category] (a category label).
  Future<List<Product>> productsByCategory(String category);

  /// Free-text search against product name/brand — the dashboard search bar.
  Future<List<Product>> searchProducts(String query);

  /// A single product by id, for the detail screen.
  Future<Product> productById(String id);

  /// Products in the same category as [id], excluding it — for the detail
  /// screen's "Similar products" row.
  Future<List<Product>> similarProducts(String id);
}
