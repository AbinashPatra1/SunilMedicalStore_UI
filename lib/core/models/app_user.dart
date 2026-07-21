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
    required this.email,
    required this.role,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;

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
      other.email == email &&
      other.role == role;

  @override
  int get hashCode => Object.hash(id, name, email, role);
}
