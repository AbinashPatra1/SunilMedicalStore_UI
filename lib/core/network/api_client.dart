import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_config.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';

/// Shared [Dio] client for all repositories.
///
/// Attaches the current Firebase ID token as a bearer token on every request
/// — the `firebase_auth` SDK keeps it fresh, so no manual refresh logic is
/// needed here. Requests made before any sign-in simply go out without the
/// header (the backend then returns 401, surfaced as [ApiException]).
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

  return dio;
});
