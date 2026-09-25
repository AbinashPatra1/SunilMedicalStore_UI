import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/models/order.dart';
import 'package:sunil_medical_store/features/profile/domain/customer_profile.dart';
import 'package:sunil_medical_store/features/profile/domain/lab_test.dart';
import 'package:sunil_medical_store/features/profile/domain/past_appointment.dart';
import 'package:sunil_medical_store/features/profile/presentation/providers/profile_repository_provider.dart';
import 'package:sunil_medical_store/core/paging/paged.dart';

export 'package:sunil_medical_store/features/profile/presentation/providers/profile_repository_provider.dart'
    show profileRepositoryProvider;

/// The signed-in customer's account details (Account screen).
final customerProfileProvider = FutureProvider<CustomerProfile>((ref) {
  return ref.watch(profileRepositoryProvider).customerProfile();
});

final pastAppointmentsProvider =
    AsyncNotifierProvider<PastAppointmentsNotifier, PagedState<PastAppointment>>(PastAppointmentsNotifier.new);

final pastOrdersProvider = AsyncNotifierProvider<PastOrdersNotifier, PagedState<Order>>(PastOrdersNotifier.new);

class PastAppointmentsNotifier extends PagedNotifier<PastAppointment> {
  @override
  Future<PagedState<PastAppointment>> build() => loadFirst();

  @override
  Future<PageResult<PastAppointment>> fetch(int page) =>
      ref.read(profileRepositoryProvider).pastAppointmentsPage(page: page);

  @override
  Object keyOf(PastAppointment item) => item.id;
}

class PastOrdersNotifier extends PagedNotifier<Order> {
  @override
  Future<PagedState<Order>> build() => loadFirst();

  @override
  Future<PageResult<Order>> fetch(int page) => ref.read(profileRepositoryProvider).pastOrdersPage(page: page);

  @override
  Object keyOf(Order item) => item.id;
}

/// A single order by id — see [ProfileRepository.orderById].
final orderByIdProvider = FutureProvider.family<Order, String>((ref, id) {
  return ref.watch(profileRepositoryProvider).orderById(id);
});

final labTestsProvider = AsyncNotifierProvider<BookedLabTestsNotifier, PagedState<LabTest>>(BookedLabTestsNotifier.new);

class BookedLabTestsNotifier extends PagedNotifier<LabTest> {
  @override
  Future<PagedState<LabTest>> build() => loadFirst();

  @override
  Future<PageResult<LabTest>> fetch(int page) => ref.read(profileRepositoryProvider).labTestsPage(page: page);

  @override
  Object keyOf(LabTest item) => item.id;
}
