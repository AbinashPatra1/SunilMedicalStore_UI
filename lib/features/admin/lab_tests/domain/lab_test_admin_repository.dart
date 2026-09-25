import 'package:sunil_medical_store/features/lab_tests/domain/lab_test.dart';
import 'package:sunil_medical_store/core/paging/paged.dart';

/// Admin-side CRUD over the lab-test catalog: list-all, read-one, create,
/// update, and delete. Brand new — distinct from the admin Pathology
/// feature (`features/admin/pathology`), which manages customer *bookings*
/// of already-existing tests, not the test definitions themselves.
///
/// The customer-facing `LabTestRepository` also reads tests, but from a
/// different endpoint — kept separate so reads/writes evolve independently,
/// matching the Inventory/Product split.
abstract interface class LabTestAdminRepository {
  Future<List<LabTest>> list();

  /// One page of the catalog.
  Future<PageResult<LabTest>> listPage({required int page, int pageSize = kAdminPageSize});

  /// Single test by id.
  Future<LabTest> getById(String id);

  /// Creates a new test. Returns the server-assigned id/state.
  Future<LabTest> create(LabTestInput input);

  /// Updates an existing test. Returns the refreshed test.
  Future<LabTest> update(String id, LabTestInput input);

  Future<void> delete(String id);
}

/// Value object for create/update requests. Server assigns [LabTest.id] on
/// create; the client never sets it.
class LabTestInput {
  const LabTestInput({
    required this.name,
    required this.description,
    required this.labName,
    required this.price,
    this.mrp,
    required this.sampleType,
    required this.reportTime,
    required this.fastingRequired,
    required this.parameters,
    this.tags = const [],
  });

  final String name;
  final String description;
  final String labName;

  /// Price in rupees.
  final int price;

  /// Pre-discount price in rupees, when discounted.
  final int? mrp;

  /// e.g. `Blood`, `Urine`, `Blood & Urine`.
  final String sampleType;

  /// e.g. `Within 24 hours`.
  final String reportTime;
  final bool fastingRequired;

  /// The individual parameters covered by the test.
  final List<String> parameters;

  /// Free-text keywords (including symptom-style ones) the admin adds
  /// purely to widen what search matches — never shown to customers.
  final List<String> tags;
}
