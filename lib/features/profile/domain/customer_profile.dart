/// The customer's gender, used to pick a placeholder avatar.
enum Gender {
  male,
  female,
  other;

  String get label => switch (this) {
    Gender.male => 'Male',
    Gender.female => 'Female',
    Gender.other => 'Other',
  };
}

/// A single entry in the customer's medical history.
class MedicalRecord {
  const MedicalRecord({required this.id, required this.title, required this.type, required this.date});

  final String id;
  final String title;

  /// e.g. `Allergy`, `Condition`, `Report`.
  final String type;
  final DateTime date;
}

/// The customer's account details shown on the Account screen.
///
/// [gender], [dateOfBirth] and [email] are nullable — the backend doesn't
/// require them at signup; they're only set once a user fills them in via
/// [ProfileRepository.upsertProfile].
class CustomerProfile {
  const CustomerProfile({
    required this.fullName,
    this.gender,
    this.dateOfBirth,
    required this.phoneNumber,
    this.email,
    required this.medicalRecords,
  });

  final String fullName;
  final Gender? gender;
  final DateTime? dateOfBirth;
  final String phoneNumber;
  final String? email;
  final List<MedicalRecord> medicalRecords;
}
