import 'package:sunil_medical_store/features/profile/domain/past_appointment.dart';

/// Admin's view of an appointment: everything [PastAppointment] carries, plus
/// which user booked it. Kept as a separate class (not a subclass) because the
/// customer's `PastAppointment` never has user info — server sends a
/// different DTO to the admin endpoints.
class AdminAppointment {
  const AdminAppointment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.doctorId,
    required this.doctorName,
    required this.specialization,
    required this.dateTime,
    required this.status,
    required this.fee,
    this.appointmentNumber,
  });

  final String id;

  /// Human-readable appointment number (`DASMS-<mmyy>-<seq>`). `null` for
  /// appointments booked before this numbering existed — no backfill.
  final String? appointmentNumber;

  final String userId;
  final String userName;

  /// National 10-digit number.
  final String userPhone;

  final String doctorId;
  final String doctorName;
  final String specialization;
  final DateTime dateTime;
  final AppointmentStatus status;
  final int fee;

  /// ISO weekday (1..7) of [dateTime] — convenient for the day-of-week filter.
  int get weekday => dateTime.weekday;
}
