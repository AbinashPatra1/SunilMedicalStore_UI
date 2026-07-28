import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/models/order.dart';
import 'package:sunil_medical_store/features/profile/domain/customer_profile.dart';
import 'package:sunil_medical_store/features/profile/domain/lab_test.dart';
import 'package:sunil_medical_store/features/profile/domain/past_appointment.dart';
import 'package:sunil_medical_store/features/profile/presentation/providers/profile_repository_provider.dart';

export 'package:sunil_medical_store/features/profile/presentation/providers/profile_repository_provider.dart'
    show profileRepositoryProvider;

/// The signed-in customer's account details (Account screen).
final customerProfileProvider = FutureProvider<CustomerProfile>((ref) {
  return ref.watch(profileRepositoryProvider).customerProfile();
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
