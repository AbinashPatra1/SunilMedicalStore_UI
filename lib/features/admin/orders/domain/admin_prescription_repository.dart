import 'package:sunil_medical_store/core/models/prescription.dart';
import 'package:sunil_medical_store/features/admin/orders/domain/admin_prescription.dart';
import 'package:sunil_medical_store/core/paging/paged.dart';

/// Admin's read + review surface for prescriptions across all users.
abstract interface class AdminPrescriptionRepository {
  /// All prescriptions matching [status] (or every status, if `null`),
  /// newest first.
  Future<List<AdminPrescription>> list({PrescriptionStatus? status});

  /// One page of prescriptions, optionally narrowed by [status].
  Future<PageResult<AdminPrescription>> listPage({PrescriptionStatus? status, required int page, int pageSize = kAdminPageSize});

  /// Single prescription by id.
  Future<AdminPrescription> getById(String id);

  /// Approves or rejects a prescription. [note] is typically the rejection
  /// reason — optional either way.
  Future<AdminPrescription> review(
    String id, {
    required PrescriptionStatus status,
    String? note,
  });
}
