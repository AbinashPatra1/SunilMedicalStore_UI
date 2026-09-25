import 'dart:io';

import 'package:sunil_medical_store/core/models/prescription.dart';
import 'package:sunil_medical_store/core/paging/paged.dart';

/// Uploads and reads back the caller's own prescriptions.
///
/// Reachable from two places: the Pharmacy tab's "Prescription" button
/// (general upload, e.g. to reorder from), and checkout when the cart holds
/// an Rx-flagged item (attach one before "Order Now" is enabled).
abstract interface class PrescriptionRepository {
  /// The caller's prescriptions, newest first.
  Future<List<Prescription>> list();

  /// One page of the caller's prescriptions, newest first.
  Future<PageResult<Prescription>> listPage({required int page, int pageSize = kPageSize});

  /// Uploads [imageFile] and returns the created (pending-review)
  /// [Prescription]. Implementations own how/where the image bytes are
  /// actually stored (see `ApiPrescriptionRepository`).
  Future<Prescription> upload(File imageFile);

  Future<Prescription> getById(String id);
}
