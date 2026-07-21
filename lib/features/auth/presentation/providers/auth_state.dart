import 'package:sunil_medical_store/core/models/app_user.dart';

/// Where the app is in the auth lifecycle.
enum AuthStatus {
  /// Still resolving whether a session exists (splash is shown).
  unknown,

  /// A user is signed in.
  authenticated,

  /// No user is signed in.
  unauthenticated,
}

/// Immutable auth state exposed by `authControllerProvider`.
///
/// [isSubmitting] is separate from [status] so the login button can show a
/// spinner without the router treating the user as signed in mid-request.
class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isSubmitting = false,
    this.errorMessage,
  });

  const AuthState.unknown() : this();

  const AuthState.submitting() : this(status: AuthStatus.unauthenticated, isSubmitting: true);

  const AuthState.authenticated(AppUser user) : this(status: AuthStatus.authenticated, user: user);

  const AuthState.unauthenticated({String? errorMessage})
    : this(status: AuthStatus.unauthenticated, errorMessage: errorMessage);

  final AuthStatus status;
  final AppUser? user;
  final bool isSubmitting;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;
}
