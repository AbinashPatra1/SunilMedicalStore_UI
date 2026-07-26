import 'package:sunil_medical_store/features/auth/domain/auth_account.dart';

/// Contract for phone-number + OTP authentication, implemented by the data
/// layer (Firebase).
///
/// The two-step [sendOtp] / [verifyOtp] shape mirrors Firebase Phone Auth.
/// [authStateChanges] is the source of truth for the current session, so the
/// app restores logins across restarts automatically.
abstract interface class AuthRepository {
  /// Emits the current [AuthAccount] whenever the session changes; `null` when
  /// signed out. Emits the persisted session on startup.
  Stream<AuthAccount?> authStateChanges();

  /// Requests an OTP for [phoneNumber] (E.164, e.g. `+919812345678`). Returns
  /// an opaque verification id to pass to [verifyOtp]. Throws [AuthException].
  Future<String> sendOtp({required String phoneNumber});

  /// Signs the user in with [smsCode] for the given [verificationId]. The new
  /// session then flows through [authStateChanges]. Throws [AuthException].
  Future<void> verifyOtp({required String verificationId, required String smsCode});

  /// Persists [fullName] on the signed-in user and returns the refreshed
  /// account. Used to finish onboarding for a new user.
  Future<AuthAccount> completeProfile({required String fullName});

  Future<void> signOut();
}

/// Domain-level authentication failure with a user-presentable [message].
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}
