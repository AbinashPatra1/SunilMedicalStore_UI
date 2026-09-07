import 'package:sunil_medical_store/features/admin/pathology/domain/admin_lab_test_booking.dart';
import 'package:sunil_medical_store/features/profile/domain/lab_test.dart';

/// Query filters for [AdminLabTestRepository.list]. Any field left null
/// means "don't filter on this dimension".
class LabTestBookingFilters {
  const LabTestBookingFilters({this.search, this.status, this.dateFrom, this.dateTo});

  /// Free-text match against test name, user name and phone (server-side).
  final String? search;
  final LabTestStatus? status;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  bool get isEmpty =>
      (search == null || search!.isEmpty) && status == null && dateFrom == null && dateTo == null;
}

/// Admin's read + write surface for lab-test bookings across all users.
abstract interface class AdminLabTestRepository {
  /// All bookings matching [filters], newest first.
  Future<List<AdminLabTestBooking>> list(LabTestBookingFilters filters);

  /// Single booking by id.
  Future<AdminLabTestBooking> getById(String id);

  /// Changes a booking's status (advance to `inSession`/`completed`, or
  /// cancel). Admin can set any status, including `cancelled`.
  Future<AdminLabTestBooking> updateStatus(String id, LabTestStatus status);
}
