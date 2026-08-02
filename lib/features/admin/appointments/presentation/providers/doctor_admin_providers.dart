import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_client.dart';
import 'package:sunil_medical_store/features/admin/appointments/data/api_doctor_admin_repository.dart';
import 'package:sunil_medical_store/features/admin/appointments/domain/doctor_admin_repository.dart';
import 'package:sunil_medical_store/features/appointments/domain/doctor.dart';

/// Provides the admin-side [DoctorAdminRepository].
final doctorAdminRepositoryProvider = Provider<DoctorAdminRepository>((ref) {
  return ApiDoctorAdminRepository(ref.watch(dioProvider));
});

/// All doctors, for the admin list.
final adminDoctorsProvider = FutureProvider<List<Doctor>>((ref) {
  return ref.watch(doctorAdminRepositoryProvider).list();
});

/// A single doctor for the edit form.
final adminDoctorByIdProvider =
    FutureProvider.family<Doctor, String>((ref, id) {
  return ref.watch(doctorAdminRepositoryProvider).getById(id);
});
