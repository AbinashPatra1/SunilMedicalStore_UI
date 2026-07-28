import 'package:dio/dio.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/features/appointments/domain/doctor.dart';
import 'package:sunil_medical_store/features/appointments/domain/doctor_repository.dart';

/// [DoctorRepository] backed by the real API.
///
/// `GET /doctors` returns every doctor's recurring weekly availability
/// pattern (not date-specific bookings) — "this week" highlighting is a
/// client-side display concern, handled by `WeekRange`/`WeeklyAvailability`.
class ApiDoctorRepository implements DoctorRepository {
  ApiDoctorRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<Doctor>> doctorsAvailableThisWeek() async {
    try {
      final response = await _dio.get<List<dynamic>>('/doctors');
      return (response.data ?? const []).cast<Map<String, dynamic>>().map(_fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

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
