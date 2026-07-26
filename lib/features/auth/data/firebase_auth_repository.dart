import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:sunil_medical_store/core/models/user_role.dart';
import 'package:sunil_medical_store/features/auth/domain/auth_account.dart';
import 'package:sunil_medical_store/features/auth/domain/auth_repository.dart';

/// [AuthRepository] backed by Firebase Phone Authentication.
///
/// Role is read from the ID token's custom claims (`role`), defaulting to
/// [UserRole.customer]. The display name is stored on the Firebase user
/// itself, so no separate profile database is required.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository([FirebaseAuth? auth])
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  Stream<AuthAccount?> authStateChanges() {
    return _auth.authStateChanges().asyncMap(
      (user) async => user == null ? null : await _accountFor(user),
    );
  }

  Future<AuthAccount> _accountFor(User user) async {
    final token = await user.getIdTokenResult();
    final role = token.claims?['role'] == 'admin'
        ? UserRole.admin
        : UserRole.customer;
    return AuthAccount(
      uid: user.uid,
      phoneNumber: _nationalNumber(user.phoneNumber),
      role: role,
      displayName: user.displayName,
    );
  }

  @override
  Future<String> sendOtp({required String phoneNumber}) {
    final completer = Completer<String>();
    _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        // Android instant verification: sign in directly. authStateChanges
        // then drives the UI, so the OTP step is simply skipped.
        try {
          await _auth.signInWithCredential(credential);
        } catch (_) {}
        if (!completer.isCompleted) completer.complete('auto-verified');
      },
      verificationFailed: (e) {
        if (!completer.isCompleted) {
          completer.completeError(AuthException(_messageFor(e)));
        }
      },
      codeSent: (verificationId, _) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
    return completer.future;
  }

  @override
  Future<void> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  @override
  Future<AuthAccount> completeProfile({required String fullName}) async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthException('Not signed in.');
    await user.updateDisplayName(fullName);
    await user.reload();
    return _accountFor(_auth.currentUser!);
  }

  @override
  Future<void> signOut() => _auth.signOut();

  /// Strips a leading country code so the app works with 10-digit numbers.
  String _nationalNumber(String? e164) {
    if (e164 == null) return '';
    final digits = e164.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('91')) return digits.substring(2);
    if (digits.length > 10) return digits.substring(digits.length - 10);
    return digits;
  }

  String _messageFor(FirebaseAuthException e) => switch (e.code) {
    'invalid-phone-number' => 'Enter a valid mobile number.',
    'invalid-verification-code' => 'Incorrect OTP. Please try again.',
    'invalid-verification-id' => 'The OTP expired. Please request a new one.',
    'session-expired' => 'The OTP expired. Please request a new one.',
    'too-many-requests' => 'Too many attempts. Please try again later.',
    'network-request-failed' => 'Network error. Check your connection.',
    _ => e.message ?? 'Authentication failed. Please try again.',
  };
}
