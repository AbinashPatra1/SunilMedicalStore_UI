import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/features/appointments/domain/appointment_repository.dart';

/// [AppointmentRepository] backed by the real API.
class ApiAppointmentRepository implements AppointmentRepository {
  ApiAppointmentRepository(this._dio);

  final Dio _dio;
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  Future<void> book({
    required String doctorId,
    required DateTime date,
    required String timeSlot,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/appointments',
        data: {
          'doctorId': doctorId,
          'date': _dateFormat.format(date),
          'timeSlot': timeSlot,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
