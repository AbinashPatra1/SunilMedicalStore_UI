import 'package:dio/dio.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/features/admin/inventory/domain/inventory_repository.dart';
import 'package:sunil_medical_store/features/medicines/domain/product.dart';

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
  );
}
