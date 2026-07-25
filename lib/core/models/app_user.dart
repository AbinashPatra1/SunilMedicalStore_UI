import 'package:sunil_medical_store/core/models/user_role.dart';

/// The authenticated user, shared across features.
///
/// This is a plain domain model with no Firebase/JSON coupling. The data
/// layer (e.g. a Firebase or REST repository) is responsible for mapping its
/// own DTOs into this type, so the rest of the app depends only on `core`.
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.role,
  });

  final String id;
  final String name;

  /// 10-digit Indian mobile number the user signed in with (no country code).
  final String phoneNumber;
  final UserRole role;

  /// Number formatted for display, e.g. `+91 98765 43210`.
  String get displayPhone {
    if (phoneNumber.length != 10) return phoneNumber;
    return '+91 ${phoneNumber.substring(0, 5)} ${phoneNumber.substring(5)}';
  }

  /// Up-to-two-letter initials for avatar placeholders.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.id == id &&
      other.name == name &&
      other.phoneNumber == phoneNumber &&
      other.role == role;

  @override
  int get hashCode => Object.hash(id, name, phoneNumber, role);
}
