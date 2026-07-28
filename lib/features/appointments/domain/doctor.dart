/// A doctor bookable through the app.
///
/// Plain domain model with no data-source coupling; the data layer maps its
/// own DTOs into this type.
class Doctor {
  const Doctor({
    required this.id,
    required this.name,
    required this.specialization,
    required this.qualification,
    required this.experienceYears,
    required this.rating,
    required this.consultationFee,
    required this.availableWeekdays,
    required this.availableTime,
    this.photoUrl,
  });

  final String id;
  final String name;
  final String specialization;
  final String qualification;
  final int experienceYears;
  final double rating;

  /// Consultation fee in rupees.
  final int consultationFee;

  /// Weekdays the doctor is available, as `DateTime.monday`..`DateTime.sunday`.
  final List<int> availableWeekdays;

  /// Human-readable consulting hours, e.g. `10:00 AM – 1:00 PM`.
  final String availableTime;

  /// Photo URL, when the catalog has one (`null` falls back to initials).
  final String? photoUrl;

  /// Up-to-two-letter initials for the avatar placeholder.
  String get initials {
    final parts = name.replaceFirst(RegExp(r'^Dr\.?\s*'), '').trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
