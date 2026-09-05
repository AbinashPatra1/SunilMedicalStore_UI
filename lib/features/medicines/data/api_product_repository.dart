import 'package:dio/dio.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/features/medicines/domain/product.dart';
import 'package:sunil_medical_store/features/medicines/domain/product_repository.dart';

/// [ProductRepository] backed by the real catalog API.
class ApiProductRepository implements ProductRepository {
  ApiProductRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<Product>> suggestedProducts() => _getList('/catalog/products/suggested');

  @override
  Future<List<Product>> allProducts() => _getList('/catalog/products');

  @override
  Future<List<Product>> productsByCategory(String category) =>
      _getList('/catalog/products', queryParameters: {'category': category});

  @override
  Future<List<Product>> searchProducts(String query) =>
      _getList('/catalog/products', queryParameters: {'search': query});

  @override
  Future<Product> productById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/catalog/products/$id');
      return _fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<List<Product>> similarProducts(String id) => _getList('/catalog/products/$id/similar');

  Future<List<Product>> _getList(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get<List<dynamic>>(path, queryParameters: queryParameters);
      return (response.data ?? const []).cast<Map<String, dynamic>>().map(_fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

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
