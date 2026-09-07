/// Status of a booked lab test.
enum LabTestStatus {
  scheduled,
  inSession,
  completed,
  cancelled;

  String get label => switch (this) {
    LabTestStatus.scheduled => 'Scheduled',
    LabTestStatus.inSession => 'In Session',
    LabTestStatus.completed => 'Completed',
    LabTestStatus.cancelled => 'Cancelled',
  };

  /// The next status in the linear lab-test flow — same one-step-at-a-time
  /// admin swipe pattern as [OrderStatus.next]. `null` once there's no next
  /// step (already `completed`, or `cancelled`).
  LabTestStatus? get next => switch (this) {
    LabTestStatus.scheduled => LabTestStatus.inSession,
    LabTestStatus.inSession => LabTestStatus.completed,
    LabTestStatus.completed => null,
    LabTestStatus.cancelled => null,
  };

  /// Swipe-bar label for advancing from this status to [next]. `null` when
  /// [next] is `null` (nothing to advance to).
  String? get advanceLabel => switch (this) {
    LabTestStatus.scheduled => 'Start Session',
    LabTestStatus.inSession => 'Mark Completed',
    LabTestStatus.completed => null,
    LabTestStatus.cancelled => null,
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
