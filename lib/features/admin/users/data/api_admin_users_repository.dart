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

  @override
  Future<AdminUser> getById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/admin/users/$id');
      return _fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<AdminUser> create({
    required String fullName,
    required String phoneNumber,
    String? email,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/admin/users',
        data: {'fullName': fullName, 'phoneNumber': phoneNumber, 'email': email},
      );
      return _fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<AdminUser> update(String id, {required String fullName, String? email}) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/admin/users/$id',
        data: {'fullName': fullName, 'email': email},
      );
      return _fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete<void>('/admin/users/$id');
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
