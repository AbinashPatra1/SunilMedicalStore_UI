import 'package:dio/dio.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/features/admin/appointments/domain/doctor_admin_repository.dart';
import 'package:sunil_medical_store/features/appointments/domain/doctor.dart';

/// [DoctorAdminRepository] backed by `/v1/admin/doctors`. See API doc §Admin.
class ApiDoctorAdminRepository implements DoctorAdminRepository {
  ApiDoctorAdminRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<Doctor>> list() async {
    try {
      final response = await _dio.get<List<dynamic>>('/admin/doctors');
      return (response.data ?? const []).cast<Map<String, dynamic>>().map(_fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<Doctor> getById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/admin/doctors/$id');
      return _fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<Doctor> create(DoctorInput input) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/admin/doctors',
        data: _toJson(input),
      );
      return _fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<Doctor> update(String id, DoctorInput input) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/admin/doctors/$id',
        data: _toJson(input),
      );
      return _fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete<void>('/admin/doctors/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Map<String, dynamic> _toJson(DoctorInput input) => {
    'name': input.name,
    'specialization': input.specialization,
    'qualification': input.qualification,
    'experienceYears': input.experienceYears,
    'rating': input.rating,
    'consultationFee': input.consultationFee,
    'availableWeekdays': input.availableWeekdays,
    'availableTime': input.availableTime,
    'photoUrl': ?input.photoUrl,
  };

  Doctor _fromJson(Map<String, dynamic> json) => Doctor(
    id: json['id'] as String,
    name: json['name'] as String,
    specialization: json['specialization'] as String,
    qualification: json['qualification'] as String,
    experienceYears: json['experienceYears'] as int,
    rating: (json['rating'] as num).toDouble(),
    consultationFee: json['consultationFee'] as int,
    availableWeekdays: ((json['availableWeekdays'] as List?) ?? const []).cast<int>(),
    availableTime: json['availableTime'] as String,
    photoUrl: json['photoUrl'] as String?,
  );
}
