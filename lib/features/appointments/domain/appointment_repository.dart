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

  /// Cancels the caller's own appointment [id]. Throws [ApiException] if it's
  /// not cancellable (already completed/cancelled) or not the caller's.
  Future<void> cancel(String id);

  /// Rates the doctor for the caller's own completed appointment [id] with
  /// [stars] (1–5). Throws [ApiException] if the appointment isn't
  /// completed, isn't the caller's, or has already been rated.
  Future<void> rate(String id, int stars);
}
