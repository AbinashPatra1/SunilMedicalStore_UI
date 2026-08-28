import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/models/prescription.dart';
import 'package:sunil_medical_store/core/network/api_client.dart';
import 'package:sunil_medical_store/features/prescriptions/data/api_prescription_repository.dart';
import 'package:sunil_medical_store/features/prescriptions/domain/prescription_repository.dart';

final prescriptionRepositoryProvider = Provider<PrescriptionRepository>((ref) {
  return ApiPrescriptionRepository(ref.watch(dioProvider));
});

/// The caller's prescriptions, newest first.
final prescriptionsProvider = FutureProvider<List<Prescription>>((ref) {
  return ref.watch(prescriptionRepositoryProvider).list();
});
