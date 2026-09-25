import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_client.dart';
import 'package:sunil_medical_store/features/admin/inventory/data/api_inventory_repository.dart';
import 'package:sunil_medical_store/features/admin/inventory/domain/inventory_repository.dart';
import 'package:sunil_medical_store/features/admin/inventory/presentation/providers/inventory_filters_provider.dart';
import 'package:sunil_medical_store/features/medicines/domain/product.dart';
import 'package:sunil_medical_store/core/paging/paged.dart';
import 'package:sunil_medical_store/features/admin/inventory/domain/inventory_filters.dart';

/// Provides the [InventoryRepository] implementation (real API).
final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return ApiInventoryRepository(ref.watch(dioProvider));
});

/// The admin catalog for the active filters, paged (numbered pages).
/// Category, type, search and in-stock go to the backend, and
/// `InventoryListScreen` applies the same filters client-side too, so a
/// backend that ignores any of them still shows the right rows.
final adminInventoryListProvider =
    AsyncNotifierProvider<AdminInventoryNotifier, PagedState<Product>>(AdminInventoryNotifier.new);

class AdminInventoryNotifier extends PagedNotifier<Product> {
  late AdminInventoryFilters _filters;

  @override
  int get pageSize => kAdminPageSize;

  @override
  Future<PagedState<Product>> build() {
    _filters = ref.watch(adminInventoryFiltersProvider);
    return loadFirst();
  }

  @override
  Future<PageResult<Product>> fetch(int page) => ref.read(inventoryRepositoryProvider).listPage(
    category: _filters.category?.label,
    type: _filters.type,
    search: _filters.search,
    inStockOnly: _filters.inStockOnly,
    page: page,
    pageSize: pageSize,
  );

  @override
  Object keyOf(Product item) => item.id;
}

/// A single product for the edit form. `null` id means Add mode.
final adminProductByIdProvider =
    FutureProvider.family<Product, String>((ref, id) {
  return ref.watch(inventoryRepositoryProvider).getById(id);
});
