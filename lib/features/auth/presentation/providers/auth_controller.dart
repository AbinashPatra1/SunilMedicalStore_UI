import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/features/auth/data/mock_auth_repository.dart';
import 'package:sunil_medical_store/features/auth/domain/auth_repository.dart';
import 'package:sunil_medical_store/features/auth/presentation/providers/auth_state.dart';

/// Provides the [AuthRepository] implementation.
///
/// Swap [MockAuthRepository] for a Firebase-backed repository here when the
/// real auth flow lands — nothing else needs to change.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});

/// Holds and mutates the app's [AuthState].
final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Kick off session restore; the router keeps the user on the splash
    // screen while status is `unknown`.
    _restoreSession();
    return const AuthState.unknown();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<void> _restoreSession() async {
    // Simulate checking persisted credentials on startup.
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    final user = _repository.currentUser;
    state = user == null
        ? const AuthState.unauthenticated()
        : AuthState.authenticated(user);
  }

  /// Attempts a (mock) sign-in. Errors surface via [AuthState.errorMessage].
  Future<void> signIn({required String email, required String password}) async {
    state = const AuthState.submitting();
    try {
      final user = await _repository.signIn(
        email: email.trim(),
        password: password,
      );
      state = AuthState.authenticated(user);
    } on AuthException catch (e) {
      state = AuthState.unauthenticated(errorMessage: e.message);
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AuthState.unauthenticated();
  }
}
