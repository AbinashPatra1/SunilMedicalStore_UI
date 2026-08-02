import 'package:dio/dio.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/features/admin/users/domain/admin_user.dart';
import 'package:sunil_medical_store/features/admin/users/domain/admin_users_repository.dart';

/// [AdminUsersRepository] backed by `/v1/admin/users`.
class ApiAdminUsersRepository implements AdminUsersRepository {
  ApiAdminUsersRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<AdminUser>> list({String? query}) async {
    final trimmed = query?.trim();
    try {
      final response = await _dio.get<List<dynamic>>(
        '/admin/users',
        queryParameters: {
          if (trimmed != null && trimmed.isNotEmpty) 'search': trimmed,
        },
      );
      return (response.data ?? const []).cast<Map<String, dynamic>>().map(_fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  AdminUser _fromJson(Map<String, dynamic> json) => AdminUser(
    id: json['id'] as String,
    fullName: json['fullName'] as String,
    phoneNumber: json['phoneNumber'] as String,
    email: json['email'] as String?,
  );
}
