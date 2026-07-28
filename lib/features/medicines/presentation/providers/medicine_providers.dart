import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_client.dart';
import 'package:sunil_medical_store/features/medicines/data/api_product_repository.dart';
import 'package:sunil_medical_store/features/medicines/domain/product.dart';
import 'package:sunil_medical_store/features/medicines/domain/product_repository.dart';

/// Provides the [ProductRepository] implementation.
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ApiProductRepository(ref.watch(dioProvider));
});

/// Products suggested to the customer on the home page.
final suggestedProductsProvider = FutureProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).suggestedProducts();
});

/// Products for a given category label, or all products when the key is empty.
final productsByCategoryProvider =
    FutureProvider.family<List<Product>, String>((ref, category) {
  final repo = ref.watch(productRepositoryProvider);
  return category.isEmpty
      ? repo.allProducts()
      : repo.productsByCategory(category);
});

/// A single product for the detail screen.
final productByIdProvider = FutureProvider.family<Product, String>((ref, id) {
  return ref.watch(productRepositoryProvider).productById(id);
});

/// Same-category products for the detail screen's "Similar products" row.
final similarProductsProvider = FutureProvider.family<List<Product>, String>((ref, id) {
  return ref.watch(productRepositoryProvider).similarProducts(id);
});
