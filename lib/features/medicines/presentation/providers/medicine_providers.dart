import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_client.dart';
import 'package:sunil_medical_store/features/medicines/data/api_product_repository.dart';
import 'package:sunil_medical_store/features/medicines/domain/product.dart';
import 'package:sunil_medical_store/features/medicines/domain/product_repository.dart';
import 'package:sunil_medical_store/core/paging/paged.dart';

/// Provides the [ProductRepository] implementation.
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ApiProductRepository(ref.watch(dioProvider));
});

/// Products suggested to the customer on the home page.
final suggestedProductsProvider = FutureProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).suggestedProducts();
});

/// Products for a given category label (all products when the key is empty),
/// paged for infinite scroll.
final productsByCategoryProvider =
    AsyncNotifierProvider.family<ProductsPagedNotifier, PagedState<Product>, String>(ProductsPagedNotifier.new);

/// Free-text product search results for the given query, paged. Empty query
/// isn't meant to be watched — the search screen shows a prompt instead of
/// querying with nothing.
final searchProductsProvider =
    AsyncNotifierProvider.family<ProductSearchPagedNotifier, PagedState<Product>, String>(ProductSearchPagedNotifier.new);

class ProductsPagedNotifier extends PagedNotifier<Product> {
  ProductsPagedNotifier(this.category);

  final String category;

  @override
  Future<PagedState<Product>> build() => loadFirst();

  @override
  Future<PageResult<Product>> fetch(int page) =>
      ref.read(productRepositoryProvider).productsPage(category: category, page: page);

  @override
  Object keyOf(Product item) => item.id;
}

class ProductSearchPagedNotifier extends PagedNotifier<Product> {
  ProductSearchPagedNotifier(this.query);

  final String query;

  @override
  Future<PagedState<Product>> build() => loadFirst();

  @override
  Future<PageResult<Product>> fetch(int page) =>
      ref.read(productRepositoryProvider).productsPage(search: query, page: page);

  @override
  Object keyOf(Product item) => item.id;
}

/// A single product for the detail screen.
final productByIdProvider = FutureProvider.family<Product, String>((ref, id) {
  return ref.watch(productRepositoryProvider).productById(id);
});

/// Same-category products for the detail screen's "Similar products" row.
final similarProductsProvider = FutureProvider.family<List<Product>, String>((ref, id) {
  return ref.watch(productRepositoryProvider).similarProducts(id);
});
