import 'package:sunil_medical_store/features/admin/inventory/domain/bulk_import.dart';
import 'package:sunil_medical_store/features/medicines/domain/product.dart';
import 'package:sunil_medical_store/features/medicines/domain/product_type.dart';
import 'package:sunil_medical_store/core/paging/paged.dart';

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

  /// One page of the catalog. Only [category] was supported server-side
  /// originally; [type], [search] and [inStockOnly] are sent too (see
  /// `docs/API_ENDPOINTS.md` §Pagination) and the screen also applies them
  /// client-side, so a backend that ignores them still gives right results.
  Future<PageResult<Product>> listPage({
    String? category,
    ProductType? type,
    String? search,
    bool inStockOnly = false,
    required int page,
    int pageSize = kAdminPageSize,
  });

  /// Single product by id.
  Future<Product> getById(String id);

  /// Creates a new product. Returns the server-assigned id/state.
  Future<Product> create(ProductInput input);

  /// Updates an existing product. Returns the refreshed product.
  Future<Product> update(String id, ProductInput input);

  Future<void> delete(String id);

  /// Bulk create/update from an admin-uploaded spreadsheet, already parsed
  /// and validated client-side (backlog #13) — see
  /// `docs/API_ENDPOINTS.md` §Admin — Inventory (#78). Upserts by
  /// name+brand; per-row outcome comes back in [BulkImportSummary].
  Future<BulkImportSummary> bulkImport(List<ProductInput> rows);
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
    required this.description,
    this.composition,
    this.mrp,
    this.dosage,
    this.ingredients = const [],
    this.imageUrl,
    this.packSize,
    this.type,
    this.barcode,
    this.tags = const [],
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

  /// Pack size / quantity, e.g. `10 tablets`, `125ml`, `1 piece`.
  final String? packSize;

  final ProductType? type;

  /// Scannable barcode/SKU, when set via the barcode scanner or typed
  /// manually.
  final String? barcode;

  /// Free-text keywords (including symptom-style ones) the admin adds
  /// purely to widen what search matches — never shown to customers.
  final List<String> tags;
}
