import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_client.dart';
import 'package:sunil_medical_store/features/admin/lab_tests/data/api_lab_test_admin_repository.dart';
import 'package:sunil_medical_store/features/admin/lab_tests/domain/lab_test_admin_repository.dart';
import 'package:sunil_medical_store/features/lab_tests/domain/lab_test.dart';
import 'package:sunil_medical_store/core/paging/paged.dart';

/// Provides the [LabTestAdminRepository] implementation (real API).
final labTestAdminRepositoryProvider = Provider<LabTestAdminRepository>((ref) {
  return ApiLabTestAdminRepository(ref.watch(dioProvider));
});

/// The lab-test catalog, admin view, paged (numbered pages).
final adminLabTestsProvider = AsyncNotifierProvider<AdminLabTestsNotifier, PagedState<LabTest>>(AdminLabTestsNotifier.new);

class AdminLabTestsNotifier extends PagedNotifier<LabTest> {
  @override
  int get pageSize => kAdminPageSize;

  @override
  Future<PagedState<LabTest>> build() => loadFirst();

  @override
  Future<PageResult<LabTest>> fetch(int page) =>
      ref.read(labTestAdminRepositoryProvider).listPage(page: page, pageSize: pageSize);

  @override
  Object keyOf(LabTest item) => item.id;
}

/// A single lab test for the edit form. `null` id means Add mode.
final adminLabTestByIdProvider = FutureProvider.family<LabTest, String>((ref, id) {
  return ref.watch(labTestAdminRepositoryProvider).getById(id);
});
