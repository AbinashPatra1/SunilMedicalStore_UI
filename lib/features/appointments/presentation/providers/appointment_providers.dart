import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_client.dart';
import 'package:sunil_medical_store/features/appointments/data/api_appointment_repository.dart';
import 'package:sunil_medical_store/features/appointments/data/api_doctor_repository.dart';
import 'package:sunil_medical_store/features/appointments/domain/appointment_repository.dart';
import 'package:sunil_medical_store/features/appointments/domain/doctor.dart';
import 'package:sunil_medical_store/features/appointments/domain/doctor_repository.dart';

/// Provides the [DoctorRepository] implementation.
final doctorRepositoryProvider = Provider<DoctorRepository>((ref) {
  return ApiDoctorRepository(ref.watch(dioProvider));
});

/// Doctors available in the current week (async so the UI shows loading/error).
final weeklyDoctorsProvider = FutureProvider<List<Doctor>>((ref) {
  return ref.watch(doctorRepositoryProvider).doctorsAvailableThisWeek();
});

/// Provides the [AppointmentRepository] implementation.
final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return ApiAppointmentRepository(ref.watch(dioProvider));
});
