import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/models/prescription.dart';
import 'package:sunil_medical_store/core/network/api_client.dart';
import 'package:sunil_medical_store/features/admin/orders/data/api_admin_prescription_repository.dart';
import 'package:sunil_medical_store/features/admin/orders/domain/admin_prescription.dart';
import 'package:sunil_medical_store/features/admin/orders/domain/admin_prescription_repository.dart';
import 'package:sunil_medical_store/core/paging/paged.dart';

final adminPrescriptionRepositoryProvider = Provider<AdminPrescriptionRepository>((ref) {
  return ApiAdminPrescriptionRepository(ref.watch(dioProvider));
});

/// Currently-applied status filter for the admin prescriptions list. `null` = all.
final adminPrescriptionStatusFilterProvider =
    NotifierProvider<AdminPrescriptionStatusFilterNotifier, PrescriptionStatus?>(
  AdminPrescriptionStatusFilterNotifier.new,
);

class AdminPrescriptionStatusFilterNotifier extends Notifier<PrescriptionStatus?> {
  @override
  PrescriptionStatus? build() => PrescriptionStatus.pending;

  void set(PrescriptionStatus? next) => state = next;
}

/// Admin prescriptions matching the current status filter, paged (numbered pages).
final adminPrescriptionsProvider =
    AsyncNotifierProvider<AdminPrescriptionsNotifier, PagedState<AdminPrescription>>(AdminPrescriptionsNotifier.new);

class AdminPrescriptionsNotifier extends PagedNotifier<AdminPrescription> {
  PrescriptionStatus? _status;

  @override
  int get pageSize => kAdminPageSize;

  @override
  Future<PagedState<AdminPrescription>> build() {
    _status = ref.watch(adminPrescriptionStatusFilterProvider);
    return loadFirst();
  }

  @override
  Future<PageResult<AdminPrescription>> fetch(int page) =>
      ref.read(adminPrescriptionRepositoryProvider).listPage(status: _status, page: page, pageSize: pageSize);

  @override
  Object keyOf(AdminPrescription item) => item.id;
}

/// A single admin prescription for the review screen.
final adminPrescriptionByIdProvider = FutureProvider.family<AdminPrescription, String>((ref, id) {
  return ref.watch(adminPrescriptionRepositoryProvider).getById(id);
});
