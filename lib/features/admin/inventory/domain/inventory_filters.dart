import 'package:sunil_medical_store/features/medicines/domain/product_category.dart';
import 'package:sunil_medical_store/features/medicines/domain/product_type.dart';

/// Admin Inventory's active filter/search selection. `null` category/type
/// means "All"; `search` empty means no text filter.
class AdminInventoryFilters {
  const AdminInventoryFilters({this.category, this.type, this.search = '', this.inStockOnly = false});

  final ProductCategory? category;
  final ProductType? type;
  final String search;

  /// Hide products with no stock (the list screen's "In stock only" switch).
  final bool inStockOnly;

  bool get isActive => category != null || type != null || search.isNotEmpty;

  AdminInventoryFilters withInStockOnly(bool inStockOnly) =>
      AdminInventoryFilters(category: category, type: type, search: search, inStockOnly: inStockOnly);

  AdminInventoryFilters withCategory(ProductCategory? category) =>
      AdminInventoryFilters(category: category, type: type, search: search, inStockOnly: inStockOnly);

  AdminInventoryFilters withType(ProductType? type) =>
      AdminInventoryFilters(category: category, type: type, search: search, inStockOnly: inStockOnly);

  AdminInventoryFilters withSearch(String search) =>
      AdminInventoryFilters(category: category, type: type, search: search, inStockOnly: inStockOnly);
}
