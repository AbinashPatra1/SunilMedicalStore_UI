import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/features/auth/presentation/providers/auth_controller.dart';
import 'package:sunil_medical_store/features/profile/data/mock_profile_repository.dart';
import 'package:sunil_medical_store/features/profile/domain/customer_profile.dart';
import 'package:sunil_medical_store/features/profile/domain/lab_test.dart';
import 'package:sunil_medical_store/features/profile/domain/order.dart';
import 'package:sunil_medical_store/features/profile/domain/past_appointment.dart';
import 'package:sunil_medical_store/features/profile/domain/profile_repository.dart';

/// Provides the [ProfileRepository] implementation.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return MockProfileRepository();
});

/// The customer's account details. The phone number is taken from the
/// signed-in user so it reflects the number they actually logged in with.
final customerProfileProvider = FutureProvider<CustomerProfile>((ref) async {
  final profile = await ref.watch(profileRepositoryProvider).customerProfile();
  final phone = ref.watch(authControllerProvider).user?.displayPhone;
  return phone == null ? profile : profile.copyWith(phoneNumber: phone);
});

final pastAppointmentsProvider = FutureProvider<List<PastAppointment>>((ref) {
  return ref.watch(profileRepositoryProvider).pastAppointments();
});

final pastOrdersProvider = FutureProvider<List<Order>>((ref) {
  return ref.watch(profileRepositoryProvider).pastOrders();
});

final labTestsProvider = FutureProvider<List<LabTest>>((ref) {
  return ref.watch(profileRepositoryProvider).labTests();
});
