/// Lightweight user summary shown to admins — enough for picking a user when
/// creating an appointment on their behalf, or listing customers in stats.
///
/// Not the same as `AppUser` (the signed-in identity) because it never
/// includes the caller's own record; it's a directory view over everyone.
class AdminUser {
  const AdminUser({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.email,
  });

  final String id;
  final String fullName;

  /// National 10-digit number (no country code).
  final String phoneNumber;
  final String? email;

  /// Formatted number for display, e.g. `+91 98765 43210`.
  String get displayPhone {
    if (phoneNumber.length != 10) return phoneNumber;
    return '+91 ${phoneNumber.substring(0, 5)} ${phoneNumber.substring(5)}';
  }

  /// Up-to-two-letter initials for the avatar placeholder.
  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
