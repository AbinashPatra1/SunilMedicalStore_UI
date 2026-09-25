import 'package:sunil_medical_store/features/appointments/domain/doctor.dart';
import 'package:sunil_medical_store/core/paging/paged.dart';

/// Contract for reading doctor availability, implemented by the data layer.
///
/// Kept as an interface so the mock can later be swapped for a real
/// backend-backed implementation without touching providers or widgets.
abstract interface class DoctorRepository {
  /// Doctors with at least one available day in the current week.
  Future<List<Doctor>> doctorsAvailableThisWeek();

  /// Free-text search against name/specialization/qualification/description/
  /// tags — the Doctors tab of the search screen.
  Future<List<Doctor>> searchDoctors(String query);

  /// One page of doctors matching a free-text [search].
  Future<PageResult<Doctor>> doctorsPage({String? search, required int page, int pageSize = kPageSize});
}
