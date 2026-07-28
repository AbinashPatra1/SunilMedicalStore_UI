import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_client.dart';
import 'package:sunil_medical_store/features/lab_tests/data/api_lab_test_repository.dart';
import 'package:sunil_medical_store/features/lab_tests/domain/lab_test.dart';
import 'package:sunil_medical_store/features/lab_tests/domain/lab_test_repository.dart';

/// Provides the [LabTestRepository] implementation.
final labTestRepositoryProvider = Provider<LabTestRepository>((ref) {
  return ApiLabTestRepository(ref.watch(dioProvider));
});

/// The full lab test catalog (async so the UI shows loading/error).
final labTestCatalogProvider = FutureProvider<List<LabTest>>((ref) {
  return ref.watch(labTestRepositoryProvider).allTests();
});

/// A single lab test for the detail screen.
final labTestByIdProvider = FutureProvider.family<LabTest, String>((ref, id) {
  return ref.watch(labTestRepositoryProvider).testById(id);
});
