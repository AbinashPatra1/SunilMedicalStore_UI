import 'package:sunil_medical_store/features/appointments/domain/doctor.dart';

/// Admin-side view of the doctor catalog: list-all, read-one, create, update,
/// and delete. Same [Doctor] model as the customer side reads; different
/// endpoints so admin fields (soft-delete flag, etc.) can evolve independently.
abstract interface class DoctorAdminRepository {
  Future<List<Doctor>> list();
  Future<Doctor> getById(String id);
  Future<Doctor> create(DoctorInput input);
  Future<Doctor> update(String id, DoctorInput input);
  Future<void> delete(String id);
}

/// Value object for create/update requests. Server assigns [Doctor.id] on
/// create; the client never sets it.
class DoctorInput {
  const DoctorInput({
    required this.name,
    required this.specialization,
    required this.qualification,
    required this.experienceYears,
    required this.rating,
    required this.consultationFee,
    required this.availableWeekdays,
    required this.availableTime,
    this.photoUrl,
  });

  final String name;
  final String specialization;
  final String qualification;
  final int experienceYears;
  final double rating;
  final int consultationFee;
  final List<int> availableWeekdays;
  final String availableTime;
  final String? photoUrl;
}
