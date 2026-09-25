import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_client.dart';
import 'package:sunil_medical_store/features/lab_tests/data/api_lab_test_repository.dart';
import 'package:sunil_medical_store/features/lab_tests/domain/lab_test.dart';
import 'package:sunil_medical_store/features/lab_tests/domain/lab_test_repository.dart';
import 'package:sunil_medical_store/core/paging/paged.dart';

/// Provides the [LabTestRepository] implementation.
final labTestRepositoryProvider = Provider<LabTestRepository>((ref) {
  return ApiLabTestRepository(ref.watch(dioProvider));
});

/// The lab test catalog, paged for infinite scroll.
final labTestCatalogProvider =
    AsyncNotifierProvider<LabTestCatalogNotifier, PagedState<LabTest>>(LabTestCatalogNotifier.new);

class LabTestCatalogNotifier extends PagedNotifier<LabTest> {
  @override
  Future<PagedState<LabTest>> build() => loadFirst();

  @override
  Future<PageResult<LabTest>> fetch(int page) => ref.read(labTestRepositoryProvider).testsPage(page: page);

  @override
  Object keyOf(LabTest item) => item.id;
}

/// A single lab test for the detail screen.
final labTestByIdProvider = FutureProvider.family<LabTest, String>((ref, id) {
  return ref.watch(labTestRepositoryProvider).testById(id);
});

/// Free-text lab-test search results for the given query (paged) — the
/// Pathology tab of the search screen. Empty query isn't meant to be watched.
final searchLabTestsProvider =
    AsyncNotifierProvider.family<LabTestSearchNotifier, PagedState<LabTest>, String>(LabTestSearchNotifier.new);

class LabTestSearchNotifier extends PagedNotifier<LabTest> {
  LabTestSearchNotifier(this.query);

  final String query;

  @override
  Future<PagedState<LabTest>> build() => loadFirst();

  @override
  Future<PageResult<LabTest>> fetch(int page) =>
      ref.read(labTestRepositoryProvider).testsPage(search: query, page: page);

  @override
  Object keyOf(LabTest item) => item.id;
}
