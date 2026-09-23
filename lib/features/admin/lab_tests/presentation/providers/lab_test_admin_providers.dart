import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_client.dart';
import 'package:sunil_medical_store/features/admin/lab_tests/data/api_lab_test_admin_repository.dart';
import 'package:sunil_medical_store/features/admin/lab_tests/domain/lab_test_admin_repository.dart';
import 'package:sunil_medical_store/features/lab_tests/domain/lab_test.dart';

/// Provides the [LabTestAdminRepository] implementation (real API).
final labTestAdminRepositoryProvider = Provider<LabTestAdminRepository>((ref) {
  return ApiLabTestAdminRepository(ref.watch(dioProvider));
});

/// The full lab-test catalog, admin view.
final adminLabTestsProvider = FutureProvider<List<LabTest>>((ref) {
  return ref.watch(labTestAdminRepositoryProvider).list();
});

/// A single lab test for the edit form. `null` id means Add mode.
final adminLabTestByIdProvider = FutureProvider.family<LabTest, String>((ref, id) {
  return ref.watch(labTestAdminRepositoryProvider).getById(id);
});
