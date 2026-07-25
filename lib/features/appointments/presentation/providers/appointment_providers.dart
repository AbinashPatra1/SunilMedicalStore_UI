import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/features/appointments/data/mock_doctor_repository.dart';
import 'package:sunil_medical_store/features/appointments/domain/doctor.dart';
import 'package:sunil_medical_store/features/appointments/domain/doctor_repository.dart';

/// Provides the [DoctorRepository] implementation.
///
/// Swap [MockDoctorRepository] for a backend-backed repository here when the
/// real API lands — the screen reading [weeklyDoctorsProvider] won't change.
final doctorRepositoryProvider = Provider<DoctorRepository>((ref) {
  return MockDoctorRepository();
});

/// Doctors available in the current week (async so the UI shows loading/error).
final weeklyDoctorsProvider = FutureProvider<List<Doctor>>((ref) {
  return ref.watch(doctorRepositoryProvider).doctorsAvailableThisWeek();
});
