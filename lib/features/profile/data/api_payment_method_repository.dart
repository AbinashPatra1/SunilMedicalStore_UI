import 'package:dio/dio.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/features/profile/domain/payment_method.dart';
import 'package:sunil_medical_store/features/profile/domain/payment_method_repository.dart';

/// [PaymentMethodRepository] backed by the real API.
class ApiPaymentMethodRepository implements PaymentMethodRepository {
  ApiPaymentMethodRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<PaymentMethod>> list() async {
    try {
      final response = await _dio.get<List<dynamic>>('/payment-methods');
      return (response.data ?? const []).cast<Map<String, dynamic>>().map(_fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<PaymentMethod> addUpi(String upiId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/payment-methods',
        data: {'upiId': upiId},
      );
      return _fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> setDefault(String id) async {
    try {
      await _dio.put<void>('/payment-methods/$id/default');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> remove(String id) async {
    try {
      await _dio.delete<void>('/payment-methods/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  PaymentMethod _fromJson(Map<String, dynamic> json) => PaymentMethod(
    id: json['id'] as String,
    upiId: json['upiId'] as String,
    isDefault: json['isDefault'] as bool? ?? false,
  );
}
