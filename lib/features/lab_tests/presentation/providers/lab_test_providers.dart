import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/features/lab_tests/data/mock_lab_test_repository.dart';
import 'package:sunil_medical_store/features/lab_tests/domain/lab_test.dart';
import 'package:sunil_medical_store/features/lab_tests/domain/lab_test_repository.dart';

/// Provides the [LabTestRepository] implementation.
final labTestRepositoryProvider = Provider<LabTestRepository>((ref) {
  return MockLabTestRepository();
});

/// The full lab test catalog (async so the UI shows loading/error).
final labTestCatalogProvider = FutureProvider<List<LabTest>>((ref) {
  return ref.watch(labTestRepositoryProvider).allTests();
});
