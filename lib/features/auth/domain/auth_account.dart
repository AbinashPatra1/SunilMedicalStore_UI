import 'package:sunil_medical_store/core/models/user_role.dart';

/// Raw authenticated identity from the auth provider (Firebase), before it is
/// mapped to the app-wide [AppUser].
///
/// [displayName] is `null`/empty for a brand-new user who hasn't completed
/// onboarding yet — that's what [needsProfile] detects.
class AuthAccount {
  const AuthAccount({
    required this.uid,
    required this.phoneNumber,
    required this.role,
    this.displayName,
  });

  final String uid;

  /// National 10-digit number (country code stripped) when available.
  final String phoneNumber;
  final UserRole role;
  final String? displayName;

  /// True when the user has authenticated but has no name yet.
  bool get needsProfile => displayName == null || displayName!.trim().isEmpty;
}
