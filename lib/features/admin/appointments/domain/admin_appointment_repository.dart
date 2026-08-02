import 'package:sunil_medical_store/features/admin/appointments/domain/admin_appointment.dart';
import 'package:sunil_medical_store/features/profile/domain/past_appointment.dart';

/// Query filters for [AdminAppointmentRepository.list]. Any field left null
/// means "don't filter on this dimension".
class AppointmentFilters {
  const AppointmentFilters({
    this.search,
    this.status,
    this.doctorId,
    this.dateFrom,
    this.dateTo,
    this.weekday,
  });

  /// Free-text match against user name and doctor name (server-side).
  final String? search;
  final AppointmentStatus? status;
  final String? doctorId;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  /// ISO weekday (1..7).
  final int? weekday;

  bool get isEmpty =>
      (search == null || search!.isEmpty) &&
      status == null &&
      doctorId == null &&
      dateFrom == null &&
      dateTo == null &&
      weekday == null;
}

/// Admin's read + write surface for appointments across all users.
abstract interface class AdminAppointmentRepository {
  /// All appointments matching [filters], newest first.
  Future<List<AdminAppointment>> list(AppointmentFilters filters);

  /// Single appointment by id.
  Future<AdminAppointment> getById(String id);

  /// Changes an appointment's status and/or reschedules it to [newDate].
  /// The doctor stays the same. Pass whichever fields you want changed.
  Future<AdminAppointment> update(
    String id, {
    AppointmentStatus? status,
    DateTime? newDate,
  });

  /// Creates an appointment on behalf of [userId] with [doctorId] on [date]
  /// using the doctor's advertised [timeSlot] hours.
  Future<AdminAppointment> createOnBehalf({
    required String userId,
    required String doctorId,
    required DateTime date,
    required String timeSlot,
  });
}
