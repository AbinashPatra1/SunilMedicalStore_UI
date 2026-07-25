import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/features/auth/data/mock_auth_repository.dart';
import 'package:sunil_medical_store/features/auth/domain/auth_repository.dart';
import 'package:sunil_medical_store/features/auth/presentation/providers/auth_state.dart';

/// Provides the [AuthRepository] implementation.
///
/// Swap [MockAuthRepository] for a Firebase-backed repository here when the
/// real phone-auth flow lands — nothing else needs to change.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});

/// Holds and mutates the app's [AuthState] across the phone + OTP flow.
final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  /// Verification id returned by [sendOtp], consumed by [verifyOtp].
  String? _verificationId;

  @override
  AuthState build() {
    // Kick off session restore; the router keeps the user on the splash
    // screen while status is `unknown`.
    _restoreSession();
    return const AuthState.unknown();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<void> _restoreSession() async {
    // Simulate checking a persisted session on startup.
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    final user = _repository.currentUser;
    state = user == null
        ? const AuthState.unauthenticated()
        : AuthState.authenticated(user);
  }

  /// Requests an OTP for [phoneNumber]. Returns `true` when the request
  /// succeeds so the UI can advance to the OTP step; errors surface via
  /// [AuthState.errorMessage].
  Future<bool> sendOtp(String phoneNumber) async {
    state = const AuthState.submitting();
    try {
      _verificationId = await _repository.sendOtp(phoneNumber: phoneNumber.trim());
      state = const AuthState.unauthenticated();
      return true;
    } on AuthException catch (e) {
      state = AuthState.unauthenticated(errorMessage: e.message);
      return false;
    }
  }

  /// Verifies [smsCode] against the pending OTP request. On success the user
  /// becomes authenticated and the router redirects to their home.
  Future<void> verifyOtp(String smsCode) async {
    final verificationId = _verificationId;
    if (verificationId == null) {
      state = const AuthState.unauthenticated(
        errorMessage: 'Please request an OTP first.',
      );
      return;
    }

    state = const AuthState.submitting();
    try {
      final user = await _repository.verifyOtp(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      _verificationId = null;
      state = AuthState.authenticated(user);
    } on AuthException catch (e) {
      state = AuthState.unauthenticated(errorMessage: e.message);
    }
  }

  /// Abandons the pending OTP request (e.g. user taps "Change number").
  void resetOtp() {
    _verificationId = null;
    state = const AuthState.unauthenticated();
  }

  Future<void> signOut() async {
    await _repository.signOut();
    _verificationId = null;
    state = const AuthState.unauthenticated();
  }
}
