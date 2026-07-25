import 'package:sunil_medical_store/features/appointments/domain/doctor.dart';

/// Contract for reading doctor availability, implemented by the data layer.
///
/// Kept as an interface so the mock can later be swapped for a real
/// backend-backed implementation without touching providers or widgets.
abstract interface class DoctorRepository {
  /// Doctors with at least one available day in the current week.
  Future<List<Doctor>> doctorsAvailableThisWeek();
}
