import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_client.dart';
import 'package:sunil_medical_store/features/admin/pathology/data/api_admin_lab_test_repository.dart';
import 'package:sunil_medical_store/features/admin/pathology/domain/admin_lab_test_booking.dart';
import 'package:sunil_medical_store/features/admin/pathology/domain/admin_lab_test_repository.dart';

final adminLabTestRepositoryProvider = Provider<AdminLabTestRepository>((ref) {
  return ApiAdminLabTestRepository(ref.watch(dioProvider));
});

/// Currently-applied filters for the admin lab-test bookings list. Updated
/// by the filter UI in the list screen; [adminLabTestBookingsProvider]
/// rebuilds when it changes.
final adminLabTestFiltersProvider =
    NotifierProvider<AdminLabTestFiltersNotifier, LabTestBookingFilters>(AdminLabTestFiltersNotifier.new);

class AdminLabTestFiltersNotifier extends Notifier<LabTestBookingFilters> {
  @override
  LabTestBookingFilters build() => const LabTestBookingFilters();

  void set(LabTestBookingFilters next) => state = next;
}

/// Admin lab-test bookings matching the current filters.
final adminLabTestBookingsProvider = FutureProvider<List<AdminLabTestBooking>>((ref) {
  final filters = ref.watch(adminLabTestFiltersProvider);
  return ref.watch(adminLabTestRepositoryProvider).list(filters);
});

/// A single admin lab-test booking for the detail screen.
final adminLabTestBookingByIdProvider = FutureProvider.family<AdminLabTestBooking, String>((ref, id) {
  return ref.watch(adminLabTestRepositoryProvider).getById(id);
});
