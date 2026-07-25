import 'package:sunil_medical_store/features/profile/domain/customer_profile.dart';
import 'package:sunil_medical_store/features/profile/domain/lab_test.dart';
import 'package:sunil_medical_store/features/profile/domain/order.dart';
import 'package:sunil_medical_store/features/profile/domain/past_appointment.dart';

/// Contract for the read-only profile data (account details and history),
/// implemented by the data layer.
///
/// Addresses and payment methods are mutable and handled by their own
/// in-memory controllers instead.
abstract interface class ProfileRepository {
  Future<CustomerProfile> customerProfile();
  Future<List<PastAppointment>> pastAppointments();
  Future<List<Order>> pastOrders();
  Future<List<LabTest>> labTests();
}
