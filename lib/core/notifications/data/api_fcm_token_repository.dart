import 'dart:io';

import 'package:dio/dio.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/notifications/domain/fcm_token_repository.dart';

/// [FcmTokenRepository] backed by `PUT /v1/users/me/fcm-token`.
class ApiFcmTokenRepository implements FcmTokenRepository {
  ApiFcmTokenRepository(this._dio);

  final Dio _dio;

  @override
  Future<void> register(String token) async {
    try {
      await _dio.put<void>(
        '/users/me/fcm-token',
        data: {'token': token, 'platform': Platform.isIOS ? 'ios' : 'android'},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
