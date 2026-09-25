import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_client.dart';
import 'package:sunil_medical_store/features/admin/appointments/data/api_admin_appointment_repository.dart';
import 'package:sunil_medical_store/features/admin/appointments/domain/admin_appointment.dart';
import 'package:sunil_medical_store/features/admin/appointments/domain/admin_appointment_repository.dart';
import 'package:sunil_medical_store/core/paging/paged.dart';

final adminAppointmentRepositoryProvider = Provider<AdminAppointmentRepository>((ref) {
  return ApiAdminAppointmentRepository(ref.watch(dioProvider));
});

/// Currently-applied filters for the admin appointments list. Updated by the
/// filter UI in the list screen; the [adminAppointmentsProvider] below
/// rebuilds when it changes.
final adminAppointmentFiltersProvider =
    NotifierProvider<AdminAppointmentFiltersNotifier, AppointmentFilters>(
  AdminAppointmentFiltersNotifier.new,
);

class AdminAppointmentFiltersNotifier extends Notifier<AppointmentFilters> {
  @override
  AppointmentFilters build() => const AppointmentFilters();

  void set(AppointmentFilters next) => state = next;
}

/// Admin appointments matching the current filters, paged (numbered pages).
final adminAppointmentsProvider =
    AsyncNotifierProvider<AdminAppointmentsNotifier, PagedState<AdminAppointment>>(AdminAppointmentsNotifier.new);

class AdminAppointmentsNotifier extends PagedNotifier<AdminAppointment> {
  late AppointmentFilters _filters;

  @override
  int get pageSize => kAdminPageSize;

  @override
  Future<PagedState<AdminAppointment>> build() {
    _filters = ref.watch(adminAppointmentFiltersProvider);
    return loadFirst();
  }

  @override
  Future<PageResult<AdminAppointment>> fetch(int page) =>
      ref.read(adminAppointmentRepositoryProvider).listPage(_filters, page: page, pageSize: pageSize);

  @override
  Object keyOf(AdminAppointment item) => item.id;
}

/// A single admin appointment for the edit sheet.
final adminAppointmentByIdProvider =
    FutureProvider.autoDispose.family<AdminAppointment, String>((ref, id) {
  return ref.watch(adminAppointmentRepositoryProvider).getById(id);
});
