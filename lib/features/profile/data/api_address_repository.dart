import 'package:dio/dio.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/features/profile/domain/address.dart';
import 'package:sunil_medical_store/features/profile/domain/address_repository.dart';

/// [AddressRepository] backed by the real API.
class ApiAddressRepository implements AddressRepository {
  ApiAddressRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<Address>> list() async {
    try {
      final response = await _dio.get<List<dynamic>>('/addresses');
      return (response.data ?? const []).cast<Map<String, dynamic>>().map(_fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<Address> add({
    required AddressType type,
    required String line1,
    String? line2,
    required String city,
    required String state,
    required String pincode,
    String? area,
    double? latitude,
    double? longitude,
    bool makeDefault = false,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/addresses',
        data: {
          'type': type.name,
          'line1': line1,
          'line2': line2,
          'city': city,
          'state': state,
          'pincode': pincode,
          'area': area,
          'latitude': latitude,
          'longitude': longitude,
          'makeDefault': makeDefault,
        },
      );
      return _fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> setDefault(String id) async {
    try {
      await _dio.put<void>('/addresses/$id/default');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> remove(String id) async {
    try {
      await _dio.delete<void>('/addresses/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Address _fromJson(Map<String, dynamic> json) => Address(
    id: json['id'] as String,
    type: AddressType.values.byName(json['type'] as String),
    line1: json['line1'] as String,
    line2: json['line2'] as String?,
    city: json['city'] as String,
    state: json['state'] as String,
    pincode: json['pincode'] as String,
    area: json['area'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    isDefault: json['isDefault'] as bool? ?? false,
  );
}
