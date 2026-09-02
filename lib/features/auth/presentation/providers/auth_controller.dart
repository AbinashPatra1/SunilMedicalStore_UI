import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/models/app_user.dart';
import 'package:sunil_medical_store/core/notifications/notification_service.dart';
import 'package:sunil_medical_store/features/auth/data/firebase_auth_repository.dart';
import 'package:sunil_medical_store/features/auth/domain/auth_account.dart';
import 'package:sunil_medical_store/features/auth/domain/auth_repository.dart';
import 'package:sunil_medical_store/features/auth/presentation/providers/auth_state.dart';
import 'package:sunil_medical_store/features/profile/presentation/providers/profile_repository_provider.dart';

/// Provides the [AuthRepository] implementation (Firebase Phone Auth).
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

/// Holds and mutates the app's [AuthState] across the phone + OTP + onboarding
/// flow. The Firebase session stream is the source of truth.
final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  /// Verification id from [sendOtp], consumed by [verifyOtp].
  String? _verificationId;

  /// Guards the backend bootstrap call (see [_bootstrapProfile]) to once per
  /// session, reset on sign-out.
  bool _bootstrapped = false;

  @override
  AuthState build() {
    final subscription = ref
        .watch(authRepositoryProvider)
        .authStateChanges()
        .listen(_onAccountChanged);
    ref.onDispose(subscription.cancel);
    return const AuthState.unknown();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  void _onAccountChanged(AuthAccount? account) {
    if (account == null) {
      _bootstrapped = false;
      state = const AuthState.unauthenticated();
    } else if (account.needsProfile) {
      state = const AuthState.onboarding();
    } else {
      state = AuthState.authenticated(_toAppUser(account));
      unawaited(_bootstrapProfile(account.displayName));
      unawaited(_registerForPushNotifications());
    }
  }

  AppUser _toAppUser(AuthAccount account) => AppUser(
    id: account.uid,
    name: account.displayName!.trim(),
    phoneNumber: account.phoneNumber,
    role: account.role,
  );

  /// Requests an OTP for a 10-digit Indian number. Returns `true` on success so
  /// the UI can advance to the OTP step.
  Future<bool> sendOtp(String phoneNumber) async {
    state = const AuthState.unauthenticated(isSubmitting: true);
    try {
      _verificationId = await _repository.sendOtp(
        phoneNumber: '+91${phoneNumber.trim()}',
      );
      state = const AuthState.unauthenticated();
      return true;
    } on AuthException catch (e) {
      state = AuthState.unauthenticated(errorMessage: e.message);
      return false;
    }
  }

  /// Verifies the OTP. On success the session flows through
  /// [AuthRepository.authStateChanges] and drives the next state.
  Future<void> verifyOtp(String smsCode) async {
    final verificationId = _verificationId;
    if (verificationId == null) {
      state = const AuthState.unauthenticated(errorMessage: 'Please request an OTP first.');
      return;
    }
    state = const AuthState.unauthenticated(isSubmitting: true);
    try {
      await _repository.verifyOtp(verificationId: verificationId, smsCode: smsCode.trim());
      _verificationId = null;
      // authStateChanges emits the new session -> authenticated or onboarding.
    } on AuthException catch (e) {
      state = AuthState.unauthenticated(errorMessage: e.message);
    }
  }

  /// Saves the new user's name to finish onboarding.
  Future<void> completeOnboarding(String fullName) async {
    state = const AuthState.onboarding(isSubmitting: true);
    try {
      final account = await _repository.completeProfile(fullName: fullName.trim());
      state = AuthState.authenticated(_toAppUser(account));
      unawaited(_bootstrapProfile(account.displayName));
      unawaited(_registerForPushNotifications());
    } on AuthException catch (e) {
      state = AuthState.onboarding(errorMessage: e.message);
    }
  }

  /// Best-effort, once-per-session upsert so the backend's MySQL user row
  /// exists before any other authed endpoint is called (they assume it does).
  /// Not fatal if it fails here — [ApiProfileRepository.customerProfile]
  /// self-heals on a 404 by retrying this same call.
  Future<void> _bootstrapProfile(String? fullName) async {
    if (_bootstrapped) return;
    _bootstrapped = true;
    try {
      await ref.read(profileRepositoryProvider).upsertProfile(fullName: fullName);
    } catch (_) {
      _bootstrapped = false;
    }
  }

  /// Best-effort push-notification setup: requests permission and registers
  /// this device's FCM token. Not fatal if it fails (e.g. permission denied,
  /// or the token call 404s before the backend endpoint exists) — the user
  /// just won't get pushes until the next successful attempt.
  Future<void> _registerForPushNotifications() async {
    try {
      await ref.read(notificationServiceProvider).initialize();
    } catch (_) {
      // Ignored — see doc comment above.
    }
  }

  /// Abandons the pending OTP request (e.g. user taps "Change number").
  void resetOtp() {
    _verificationId = null;
    state = const AuthState.unauthenticated();
  }

  Future<void> signOut() async {
    _verificationId = null;
    await _repository.signOut();
    // authStateChanges emits null -> unauthenticated.
  }
}
