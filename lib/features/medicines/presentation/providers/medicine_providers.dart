import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/features/medicines/data/mock_product_repository.dart';
import 'package:sunil_medical_store/features/medicines/domain/product.dart';
import 'package:sunil_medical_store/features/medicines/domain/product_repository.dart';

/// Provides the [ProductRepository] implementation.
///
/// Swap [MockProductRepository] for a backend-backed repository here when the
/// real catalog API lands — the widgets reading the providers below won't change.
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return MockProductRepository();
});

/// Products suggested to the customer on the home page.
final suggestedProductsProvider = FutureProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).suggestedProducts();
});

/// The whole catalog (used by the detail page to resolve a product + its
/// similar products by category).
final allProductsProvider = FutureProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).allProducts();
});

/// Products for a given category label, or all products when the key is empty.
final productsByCategoryProvider =
    FutureProvider.family<List<Product>, String>((ref, category) {
  final repo = ref.watch(productRepositoryProvider);
  return category.isEmpty
      ? repo.allProducts()
      : repo.productsByCategory(category);
});
