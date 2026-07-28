import 'package:dio/dio.dart';
import 'package:sunil_medical_store/features/cart/domain/promo_code.dart';
import 'package:sunil_medical_store/features/cart/domain/promo_repository.dart';

/// [PromoRepository] backed by the real API.
class ApiPromoRepository implements PromoRepository {
  ApiPromoRepository(this._dio);

  final Dio _dio;

  @override
  Future<PromoCode> validate(String code, {required int subtotal}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/promo-codes/validate',
        data: {'code': code, 'subtotal': subtotal},
      );
      final json = response.data!;
      return PromoCode(
        code: json['code'] as String,
        label: json['label'] as String,
        type: PromoType.values.byName(json['type'] as String),
        value: json['value'] as int,
        minOrder: json['minOrder'] as int? ?? 0,
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['error'] is Map) {
        final message = (data['error'] as Map)['message']?.toString();
        if (message != null) throw PromoException(message);
      }
      throw const PromoException('Could not validate the promo code. Please try again.');
    }
  }
}
