import 'package:sunil_medical_store/core/models/prescription.dart';

/// Admin's view of a prescription: everything [Prescription] carries, plus
/// which user uploaded it — mirrors the `AdminOrder`/`Order` split.
class AdminPrescription {
  const AdminPrescription({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.imageUrl,
    required this.uploadedOn,
    required this.status,
    this.note,
  });

  final String id;

  final String userId;
  final String userName;

  /// National 10-digit number.
  final String userPhone;

  final String imageUrl;
  final DateTime uploadedOn;
  final PrescriptionStatus status;

  /// Admin's note — typically a rejection reason.
  final String? note;
}
