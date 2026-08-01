import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_client.dart';
import 'package:sunil_medical_store/features/admin/inventory/data/api_inventory_repository.dart';
import 'package:sunil_medical_store/features/admin/inventory/domain/inventory_repository.dart';
import 'package:sunil_medical_store/features/medicines/domain/product.dart';

/// Provides the [InventoryRepository] implementation (real API).
final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return ApiInventoryRepository(ref.watch(dioProvider));
});

/// All products, optionally filtered by category label. `''` means unfiltered.
final adminInventoryListProvider =
    FutureProvider.family<List<Product>, String>((ref, category) {
  return ref.watch(inventoryRepositoryProvider).list(
    category: category.isEmpty ? null : category,
  );
});

/// A single product for the edit form. `null` id means Add mode.
final adminProductByIdProvider =
    FutureProvider.family<Product, String>((ref, id) {
  return ref.watch(inventoryRepositoryProvider).getById(id);
});
