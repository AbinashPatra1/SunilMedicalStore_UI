import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/models/prescription.dart';
import 'package:sunil_medical_store/core/network/api_client.dart';
import 'package:sunil_medical_store/features/prescriptions/data/api_prescription_repository.dart';
import 'package:sunil_medical_store/features/prescriptions/domain/prescription_repository.dart';
import 'package:sunil_medical_store/core/paging/paged.dart';

final prescriptionRepositoryProvider = Provider<PrescriptionRepository>((ref) {
  return ApiPrescriptionRepository(ref.watch(dioProvider));
});

/// The caller's prescriptions, newest first.
final prescriptionsProvider = FutureProvider<List<Prescription>>((ref) {
  return ref.watch(prescriptionRepositoryProvider).list();
});

/// The prescriptions list screen's paged view (infinite scroll). Checkout
/// keeps using [prescriptionsProvider] — it needs every prescription to
/// offer as an attachment.
final pagedPrescriptionsProvider =
    AsyncNotifierProvider<PrescriptionsPagedNotifier, PagedState<Prescription>>(PrescriptionsPagedNotifier.new);

class PrescriptionsPagedNotifier extends PagedNotifier<Prescription> {
  @override
  Future<PagedState<Prescription>> build() => loadFirst();

  @override
  Future<PageResult<Prescription>> fetch(int page) =>
      ref.read(prescriptionRepositoryProvider).listPage(page: page);

  @override
  Object keyOf(Prescription item) => item.id;
}
