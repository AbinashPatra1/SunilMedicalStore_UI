import 'package:sunil_medical_store/features/profile/domain/lab_test.dart';

/// Admin's view of a lab-test booking: everything the customer-facing
/// [LabTest] carries, plus which user booked it. Kept as a separate class
/// (not a subclass) because the customer's model never has user info —
/// mirrors the `AdminOrder` / `Order` split.
class AdminLabTestBooking {
  const AdminLabTestBooking({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.name,
    required this.labName,
    required this.bookedOn,
    required this.status,
    required this.amount,
    required this.parameters,
    this.timeSlot,
    this.bookingNumber,
  });

  final String id;

  /// Human-readable booking number (`PLSMS-<mmyy>-<seq>`). `null` for
  /// bookings made before this numbering existed — no backfill.
  final String? bookingNumber;

  final String userId;
  final String userName;

  /// National 10-digit number.
  final String userPhone;

  final String name;
  final String labName;

  /// The scheduled sample-collection date.
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
