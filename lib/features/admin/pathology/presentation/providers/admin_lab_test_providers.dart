import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_client.dart';
import 'package:sunil_medical_store/features/admin/pathology/data/api_admin_lab_test_repository.dart';
import 'package:sunil_medical_store/features/admin/pathology/domain/admin_lab_test_booking.dart';
import 'package:sunil_medical_store/features/admin/pathology/domain/admin_lab_test_repository.dart';
import 'package:sunil_medical_store/core/paging/paged.dart';

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

/// Admin lab-test bookings matching the current filters, paged (numbered pages).
final adminLabTestBookingsProvider =
    AsyncNotifierProvider<AdminLabTestBookingsNotifier, PagedState<AdminLabTestBooking>>(AdminLabTestBookingsNotifier.new);

class AdminLabTestBookingsNotifier extends PagedNotifier<AdminLabTestBooking> {
  late LabTestBookingFilters _filters;

  @override
  int get pageSize => kAdminPageSize;

  @override
  Future<PagedState<AdminLabTestBooking>> build() {
    _filters = ref.watch(adminLabTestFiltersProvider);
    return loadFirst();
  }

  @override
  Future<PageResult<AdminLabTestBooking>> fetch(int page) =>
      ref.read(adminLabTestRepositoryProvider).listPage(_filters, page: page, pageSize: pageSize);

  @override
  Object keyOf(AdminLabTestBooking item) => item.id;
}

/// A single admin lab-test booking for the detail screen.
final adminLabTestBookingByIdProvider = FutureProvider.autoDispose.family<AdminLabTestBooking, String>((ref, id) {
  return ref.watch(adminLabTestRepositoryProvider).getById(id);
});
