import 'package:sunil_medical_store/core/models/order.dart';
import 'package:sunil_medical_store/features/profile/domain/customer_profile.dart';
import 'package:sunil_medical_store/features/profile/domain/lab_test.dart';
import 'package:sunil_medical_store/features/profile/domain/past_appointment.dart';

/// Contract for profile data (account details and history), implemented by
/// the data layer.
///
/// Addresses and payment methods are mutable and handled by their own
/// repositories/controllers instead (see `features/profile/domain/address.dart`
/// and `payment_method.dart`).
abstract interface class ProfileRepository {
  Future<CustomerProfile> customerProfile();

  /// Upserts the caller's profile. Used both to bootstrap a brand-new user
  /// (backend row creation on first authenticated session) and for any future
  /// edit-profile flow. All fields optional except `fullName` on first create.
  Future<CustomerProfile> upsertProfile({
    String? fullName,
    String? email,
    Gender? gender,
    DateTime? dateOfBirth,
  });

  Future<List<PastAppointment>> pastAppointments();
  Future<List<Order>> pastOrders();
  Future<List<LabTest>> labTests();
}
