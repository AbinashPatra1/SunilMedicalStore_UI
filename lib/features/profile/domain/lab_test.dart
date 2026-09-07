/// Status of a booked lab test.
enum LabTestStatus {
  completed,
  scheduled,
  cancelled;

  String get label => switch (this) {
    LabTestStatus.completed => 'Completed',
    LabTestStatus.scheduled => 'Scheduled',
    LabTestStatus.cancelled => 'Cancelled',
  };
}

/// A lab test the customer booked.
class LabTest {
  const LabTest({
    required this.id,
    required this.name,
    required this.labName,
    required this.bookedOn,
    required this.status,
    required this.amount,
    required this.parameters,
    this.timeSlot,
  });

  final String id;
  final String name;
  final String labName;

  /// The scheduled sample-collection date (customer-chosen at booking).
  final DateTime bookedOn;
  final LabTestStatus status;

  /// Customer-chosen collection window (e.g. `10:00 AM – 1:00 PM`). `null`
  /// for bookings made before time-slot selection existed.
  final String? timeSlot;

  /// Amount in rupees.
  final int amount;

  /// Individual parameters measured (e.g. `Hemoglobin`, `WBC count`).
  final List<String> parameters;
}
