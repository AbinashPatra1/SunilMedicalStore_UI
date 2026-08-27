import 'package:dio/dio.dart';

/// A backend error, parsed from the API's `{ "error": { "code", "message" } }`
/// envelope. `message` is user-presentable — safe to show directly in the UI,
/// same convention as the existing `AuthException`/`PromoException` types.
class ApiException implements Exception {
  const ApiException(this.code, this.message);

  final String code;
  final String message;

  factory ApiException.fromDioException(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      final error = data['error'] as Map;
      return ApiException(
        error['code']?.toString() ?? 'unknown_error',
        error['message']?.toString() ?? 'Something went wrong.',
      );
    }
    if (e.response?.statusCode == 401) {
      return const ApiException('unauthorized', 'Please sign in again.');
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const ApiException('network_error', 'Network error. Check your connection.');
    }
    return const ApiException('unknown_error', 'Something went wrong. Please try again.');
  }

  @override
  String toString() => 'ApiException($code): $message';
}
