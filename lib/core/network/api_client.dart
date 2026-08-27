import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_config.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';

/// Shared [Dio] client for all repositories.
///
/// Attaches the current Firebase ID token as a bearer token on every request
/// — the `firebase_auth` SDK keeps it fresh, so no manual refresh logic is
/// needed here. Requests made before any sign-in simply go out without the
/// header (the backend then returns 401, surfaced as [ApiException]).
///
/// In debug builds, every request and response is logged to the console
/// (visible via `adb logcat`, filtered by tag `flutter`) — helpful for
/// diagnosing 401/500/timeouts against the local backend. The interceptor
/// is skipped in release builds to avoid leaking IDs/tokens.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: AppConstants.apiTimeout,
      receiveTimeout: AppConstants.apiTimeout,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await FirebaseAuth.instance.currentUser?.getIdToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        // debugPrint is throttled, so long response bodies don't get dropped
        // by Android's log rate limiter.
        logPrint: (obj) => debugPrint(obj.toString()),
      ),
    );
  }

  return dio;
});
