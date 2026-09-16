import 'package:sunil_medical_store/features/medicines/domain/product_category.dart';
import 'package:sunil_medical_store/features/medicines/domain/product_type.dart';

/// Admin Inventory's active filter/search selection. `null` category/type
/// means "All"; `search` empty means no text filter.
class AdminInventoryFilters {
  const AdminInventoryFilters({this.category, this.type, this.search = ''});

  final ProductCategory? category;
  final ProductType? type;
  final String search;

  bool get isActive => category != null || type != null || search.isNotEmpty;

  AdminInventoryFilters withCategory(ProductCategory? category) =>
      AdminInventoryFilters(category: category, type: type, search: search);

  AdminInventoryFilters withType(ProductType? type) =>
      AdminInventoryFilters(category: category, type: type, search: search);

  AdminInventoryFilters withSearch(String search) =>
      AdminInventoryFilters(category: category, type: type, search: search);
}
