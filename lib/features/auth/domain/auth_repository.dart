import 'package:sunil_medical_store/core/models/app_user.dart';

/// Contract for authentication, implemented by the data layer.
///
/// The presentation layer depends only on this interface, so the mock
/// implementation can later be swapped for a real Firebase-backed one without
/// touching providers or widgets.
abstract interface class AuthRepository {
  /// The currently signed-in user, or `null` if there is no active session.
  AppUser? get currentUser;

  /// Signs the user in. Throws [AuthException] on failure.
  Future<AppUser> signIn({required String email, required String password});

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
