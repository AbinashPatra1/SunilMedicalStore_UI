/// Outcome of a past appointment.
enum AppointmentStatus {
  completed,
  cancelled;

  String get label => switch (this) {
    AppointmentStatus.completed => 'Completed',
    AppointmentStatus.cancelled => 'Cancelled',
  };
}

/// An appointment the customer booked in the past.
class PastAppointment {
  const PastAppointment({
    required this.id,
    required this.doctorName,
    required this.specialization,
    required this.dateTime,
    required this.status,
    required this.fee,
  });

  final String id;
  final String doctorName;
  final String specialization;
  final DateTime dateTime;
  final AppointmentStatus status;
  final int fee;
}
