/// Outcome of an appointment.
enum AppointmentStatus {
  upcoming,
  inSession,
  completed,
  cancelled;

  String get label => switch (this) {
    AppointmentStatus.upcoming => 'Upcoming',
    AppointmentStatus.inSession => 'In Session',
    AppointmentStatus.completed => 'Completed',
    AppointmentStatus.cancelled => 'Cancelled',
  };

  /// Whether the customer can still cancel an appointment in this status —
  /// only while it hasn't started yet.
  bool get isCustomerCancellable => this == AppointmentStatus.upcoming;

  /// The next status in the linear appointment flow — same one-step-at-a-
  /// time admin swipe pattern as [OrderStatus.next]/[LabTestStatus.next].
  /// `null` once there's no next step (already `completed`, or `cancelled`).
  AppointmentStatus? get next => switch (this) {
    AppointmentStatus.upcoming => AppointmentStatus.inSession,
    AppointmentStatus.inSession => AppointmentStatus.completed,
    AppointmentStatus.completed => null,
    AppointmentStatus.cancelled => null,
  };

  /// Swipe-bar label for advancing from this status to [next]. `null` when
  /// [next] is `null` (nothing to advance to).
  String? get advanceLabel => switch (this) {
    AppointmentStatus.upcoming => 'Start Session',
    AppointmentStatus.inSession => 'Mark Completed',
    AppointmentStatus.completed => null,
    AppointmentStatus.cancelled => null,
  };
}

/// An appointment the customer booked (past, or upcoming).
class PastAppointment {
  const PastAppointment({
    required this.id,
    required this.doctorName,
    required this.specialization,
    required this.dateTime,
    required this.status,
    required this.fee,
    this.myRating,
    this.appointmentNumber,
  });

  final String id;

  /// Human-readable appointment number (`DASMS-<mmyy>-<seq>`). `null` for
  /// appointments booked before this numbering existed — no backfill.
  final String? appointmentNumber;

  final String doctorName;
  final String specialization;
  final DateTime dateTime;
  final AppointmentStatus status;
  final int fee;

  /// This customer's 1–5 rating of the doctor for this appointment, if
  /// they've already rated it. Only ever set (or settable) while
  /// [status] is [AppointmentStatus.completed].
  final int? myRating;
}
