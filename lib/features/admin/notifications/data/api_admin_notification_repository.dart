import 'package:dio/dio.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/features/admin/notifications/domain/admin_notification.dart';
import 'package:sunil_medical_store/features/admin/notifications/domain/admin_notification_repository.dart';

/// [AdminNotificationRepository] backed by `/v1/admin/notifications`.
class ApiAdminNotificationRepository implements AdminNotificationRepository {
  ApiAdminNotificationRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<AdminNotification>> list() async {
    try {
      final response = await _dio.get<List<dynamic>>('/admin/notifications');
      return (response.data ?? const []).cast<Map<String, dynamic>>().map(AdminNotification.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> markRead(String id) async {
    try {
      await _dio.put<void>('/admin/notifications/$id/read');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> markAllRead() async {
    try {
      await _dio.put<void>('/admin/notifications/read-all');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
