import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_client.dart';
import 'package:sunil_medical_store/features/admin/inventory/data/api_inventory_repository.dart';
import 'package:sunil_medical_store/features/admin/inventory/domain/inventory_repository.dart';
import 'package:sunil_medical_store/features/admin/inventory/presentation/providers/inventory_filters_provider.dart';
import 'package:sunil_medical_store/features/medicines/domain/product.dart';

/// Provides the [InventoryRepository] implementation (real API).
final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return ApiInventoryRepository(ref.watch(dioProvider));
});

/// All products for the active filters' category (`null` = unfiltered) —
/// only the category narrows the network call; type and search-text
/// filtering (backend doesn't support either yet) happen client-side in
/// `InventoryListScreen` against this same list, so refiring the request on
/// every keystroke isn't needed.
final adminInventoryListProvider = FutureProvider<List<Product>>((ref) {
  final category = ref.watch(adminInventoryFiltersProvider.select((f) => f.category));
  return ref.watch(inventoryRepositoryProvider).list(category: category?.label);
});

/// A single product for the edit form. `null` id means Add mode.
final adminProductByIdProvider =
    FutureProvider.family<Product, String>((ref, id) {
  return ref.watch(inventoryRepositoryProvider).getById(id);
});
