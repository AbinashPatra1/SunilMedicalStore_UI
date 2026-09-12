import 'package:dio/dio.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/features/admin/delivery/domain/delivery_settings.dart';
import 'package:sunil_medical_store/features/admin/delivery/domain/delivery_settings_repository.dart';

/// [DeliverySettingsRepository] backed by `/v1/delivery-settings` (read, any
/// signed-in user) and `/v1/admin/delivery-settings` (write, admin only).
class ApiDeliverySettingsRepository implements DeliverySettingsRepository {
  ApiDeliverySettingsRepository(this._dio);

  final Dio _dio;

  @override
  Future<DeliverySettings?> get() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/delivery-settings');
      final data = response.data;
      return data == null ? null : _fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<DeliverySettings> update({
    required double storeLatitude,
    required double storeLongitude,
    required double radiusKm,
    required List<DeliveryFeeTier> deliveryFeeTiers,
    required bool deliveryFeeWaived,
    required int platformFee,
    required bool platformFeeWaived,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/admin/delivery-settings',
        data: {
          'storeLatitude': storeLatitude,
          'storeLongitude': storeLongitude,
          'radiusKm': radiusKm,
          'deliveryFeeTiers': [
            for (final tier in deliveryFeeTiers) {'maxDistanceKm': tier.maxDistanceKm, 'fee': tier.fee},
          ],
          'deliveryFeeWaived': deliveryFeeWaived,
          'platformFee': platformFee,
          'platformFeeWaived': platformFeeWaived,
        },
      );
      return _fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  DeliverySettings _fromJson(Map<String, dynamic> json) => DeliverySettings(
    storeLatitude: (json['storeLatitude'] as num).toDouble(),
    storeLongitude: (json['storeLongitude'] as num).toDouble(),
    radiusKm: (json['radiusKm'] as num).toDouble(),
    deliveryFeeTiers: ((json['deliveryFeeTiers'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(
          (t) => DeliveryFeeTier(
            maxDistanceKm: (t['maxDistanceKm'] as num).toDouble(),
            fee: t['fee'] as int,
          ),
        )
        .toList(),
    deliveryFeeWaived: json['deliveryFeeWaived'] as bool? ?? false,
    platformFee: json['platformFee'] as int? ?? 0,
    platformFeeWaived: json['platformFeeWaived'] as bool? ?? false,
  );
}
