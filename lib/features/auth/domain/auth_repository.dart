import 'package:sunil_medical_store/core/models/app_user.dart';

/// Contract for phone-number + OTP authentication, implemented by the data
/// layer.
///
/// The two-step shape ([sendOtp] then [verifyOtp]) mirrors Firebase Phone
/// Authentication, so the mock implementation can later be replaced by a real
/// Firebase-backed one without changing providers or widgets.
abstract interface class AuthRepository {
  /// The currently signed-in user, or `null` if there is no active session.
  AppUser? get currentUser;

  /// Requests an OTP for [phoneNumber] (a 10-digit Indian mobile number).
  ///
  /// Returns an opaque verification id that must be passed back to
  /// [verifyOtp]. Throws [AuthException] if the number is invalid.
  Future<String> sendOtp({required String phoneNumber});

  /// Verifies [smsCode] against the challenge identified by [verificationId]
  /// and, on success, returns the signed-in [AppUser].
  ///
  /// Throws [AuthException] if the code is wrong or the challenge is unknown.
  Future<AppUser> verifyOtp({
    required String verificationId,
    required String smsCode,
  });

  /// Clears the active session.
  Future<void> signOut();
}

/// Domain-level authentication failure with a user-presentable [message].
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}
