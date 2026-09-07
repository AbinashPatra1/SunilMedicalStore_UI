/// Outcome of an appointment.
enum AppointmentStatus {
  completed,
  cancelled,
  upcoming;

  String get label => switch (this) {
    AppointmentStatus.completed => 'Completed',
    AppointmentStatus.cancelled => 'Cancelled',
    AppointmentStatus.upcoming => 'Upcoming',
  };

  /// Whether the customer can still cancel an appointment in this status.
  bool get isCustomerCancellable => this == AppointmentStatus.upcoming;
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
  });

  final String id;
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
