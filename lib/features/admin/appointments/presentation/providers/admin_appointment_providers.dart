import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_client.dart';
import 'package:sunil_medical_store/features/admin/appointments/data/api_admin_appointment_repository.dart';
import 'package:sunil_medical_store/features/admin/appointments/domain/admin_appointment.dart';
import 'package:sunil_medical_store/features/admin/appointments/domain/admin_appointment_repository.dart';

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

/// Admin appointments matching the current filters.
final adminAppointmentsProvider = FutureProvider<List<AdminAppointment>>((ref) {
  final filters = ref.watch(adminAppointmentFiltersProvider);
  return ref.watch(adminAppointmentRepositoryProvider).list(filters);
});

/// A single admin appointment for the edit sheet.
final adminAppointmentByIdProvider =
    FutureProvider.family<AdminAppointment, String>((ref, id) {
  return ref.watch(adminAppointmentRepositoryProvider).getById(id);
});
