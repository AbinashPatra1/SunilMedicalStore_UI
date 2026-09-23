import 'package:dio/dio.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/features/admin/inventory/domain/bulk_import.dart';
import 'package:sunil_medical_store/features/admin/inventory/domain/inventory_repository.dart';
import 'package:sunil_medical_store/features/medicines/domain/product.dart';
import 'package:sunil_medical_store/features/medicines/domain/product_type.dart';

/// [InventoryRepository] backed by the admin catalog API
/// (`/v1/admin/products`). See `docs/API_ENDPOINTS.md` §Admin.
class ApiInventoryRepository implements InventoryRepository {
  ApiInventoryRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<Product>> list({String? category}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/admin/products',
        queryParameters: {'category': ?category},
      );
      return (response.data ?? const []).cast<Map<String, dynamic>>().map(_fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<Product> getById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/admin/products/$id');
      return _fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<Product> create(ProductInput input) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/admin/products',
        data: _toJson(input),
      );
      return _fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<Product> update(String id, ProductInput input) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/admin/products/$id',
        data: _toJson(input),
      );
      return _fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete<void>('/admin/products/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<BulkImportSummary> bulkImport(List<ProductInput> rows) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/admin/products/bulk-import',
        data: {'rows': rows.map(_toJson).toList()},
      );
      return _summaryFromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  BulkImportSummary _summaryFromJson(Map<String, dynamic> json) {
    final results = ((json['results'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(_rowOutcomeFromJson)
        .toList();
    return BulkImportSummary(
      results: results,
      createdCount: json['createdCount'] as int? ??
          results.where((r) => r.outcome == BulkImportOutcome.created).length,
      updatedCount: json['updatedCount'] as int? ??
          results.where((r) => r.outcome == BulkImportOutcome.updated).length,
      failedCount: json['failedCount'] as int? ??
          results.where((r) => r.outcome == BulkImportOutcome.failed).length,
    );
  }

  BulkImportRowOutcome _rowOutcomeFromJson(Map<String, dynamic> json) => BulkImportRowOutcome(
    row: json['row'] as int? ?? 0,
    name: json['name'] as String? ?? '',
    brand: json['brand'] as String? ?? '',
    outcome: switch (json['outcome'] as String?) {
      'created' => BulkImportOutcome.created,
      'updated' => BulkImportOutcome.updated,
      _ => BulkImportOutcome.failed,
    },
    id: json['id'] as String?,
    reason: json['reason'] as String?,
  );

  Map<String, dynamic> _toJson(ProductInput input) => {
    'name': input.name,
    'brand': input.brand,
    'category': input.category,
    'price': input.price,
    'stock': input.stock,
    'requiresPrescription': input.requiresPrescription,
    'composition': ?input.composition,
    'mrp': ?input.mrp,
    'description': input.description,
    'dosage': ?input.dosage,
    'ingredients': input.ingredients,
    'imageUrl': ?input.imageUrl,
    'packSize': ?input.packSize,
    'type': ?input.type?.name,
    'barcode': ?input.barcode,
    'tags': input.tags,
  };

  Product _fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as String,
    name: json['name'] as String,
    brand: json['brand'] as String,
    category: json['category'] as String,
    price: json['price'] as int,
    mrp: json['mrp'] as int?,
    requiresPrescription: json['requiresPrescription'] as bool? ?? false,
    description: json['description'] as String? ?? '',
    composition: json['composition'] as String?,
    dosage: json['dosage'] as String?,
    ingredients: ((json['ingredients'] as List?) ?? const []).cast<String>(),
    imageUrl: json['imageUrl'] as String?,
    stock: json['stock'] as int? ?? 0,
    packSize: json['packSize'] as String?,
    type: ProductType.fromWireName(json['type'] as String?),
    barcode: json['barcode'] as String?,
    tags: ((json['tags'] as List?) ?? const []).cast<String>(),
  );
}
