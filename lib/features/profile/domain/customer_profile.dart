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
  const MedicalRecord({required this.title, required this.type, required this.date});

  final String title;

  /// e.g. `Allergy`, `Condition`, `Report`.
  final String type;
  final DateTime date;
}

/// The customer's account details shown on the Account screen.
class CustomerProfile {
  const CustomerProfile({
    required this.fullName,
    required this.gender,
    required this.dateOfBirth,
    required this.phoneNumber,
    required this.email,
    required this.medicalRecords,
  });

  final String fullName;
  final Gender gender;
  final DateTime dateOfBirth;
  final String phoneNumber;
  final String email;
  final List<MedicalRecord> medicalRecords;

  CustomerProfile copyWith({String? fullName, String? phoneNumber, String? email}) {
    return CustomerProfile(
      fullName: fullName ?? this.fullName,
      gender: gender,
      dateOfBirth: dateOfBirth,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      medicalRecords: medicalRecords,
    );
  }
}
