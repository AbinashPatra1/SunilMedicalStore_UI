import 'package:sunil_medical_store/core/models/prescription.dart';
import 'package:sunil_medical_store/features/admin/orders/domain/admin_prescription.dart';

/// Admin's read + review surface for prescriptions across all users.
abstract interface class AdminPrescriptionRepository {
  /// All prescriptions matching [status] (or every status, if `null`),
  /// newest first.
  Future<List<AdminPrescription>> list({PrescriptionStatus? status});

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
