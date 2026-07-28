/// Books appointments, implemented by the data layer.
abstract interface class AppointmentRepository {
  /// Books an appointment with [doctorId] on [date] for [timeSlot] (the
  /// doctor's display consulting hours, e.g. `10:00 AM – 1:00 PM`).
  /// Throws [ApiException] on failure (see `core/network/api_exception.dart`).
  Future<void> book({
    required String doctorId,
    required DateTime date,
    required String timeSlot,
  });
}
