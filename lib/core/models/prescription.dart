/// Review state of an uploaded [Prescription].
enum PrescriptionStatus {
  pending,
  approved,
  rejected;

  String get label => switch (this) {
    PrescriptionStatus.pending => 'Pending review',
    PrescriptionStatus.approved => 'Approved',
    PrescriptionStatus.rejected => 'Rejected',
  };
}

/// A prescription image a customer uploaded — either standalone (via the
/// Pharmacy "Prescription" button) or attached to an order containing an
/// Rx-flagged item at checkout.
///
/// Lives in `core/models` (not a single feature's `domain/`) because it's
/// created by the `prescriptions` feature but also read/selected from
/// `cart/checkout` and mirrored (richer, with user info) by the admin
/// review screens — the same reasoning as `Order`.
class Prescription {
  const Prescription({
    required this.id,
    required this.imageUrl,
    required this.uploadedOn,
    required this.status,
    this.note,
  });

  final String id;
  final String imageUrl;
  final DateTime uploadedOn;
  final PrescriptionStatus status;

  /// Admin's note — typically a rejection reason. `null` while pending or
  /// approved without comment.
  final String? note;
}
