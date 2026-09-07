import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/features/admin/appointments/domain/admin_appointment.dart';
import 'package:sunil_medical_store/features/admin/appointments/domain/admin_appointment_repository.dart';
import 'package:sunil_medical_store/features/profile/domain/past_appointment.dart';

/// [AdminAppointmentRepository] backed by `/v1/admin/appointments`.
class ApiAdminAppointmentRepository implements AdminAppointmentRepository {
  ApiAdminAppointmentRepository(this._dio);

  final Dio _dio;
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  Future<List<AdminAppointment>> list(AppointmentFilters filters) async {
    final search = filters.search?.trim();
    try {
      final response = await _dio.get<List<dynamic>>(
        '/admin/appointments',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (filters.status != null) 'status': filters.status!.name,
          if (filters.doctorId != null) 'doctorId': filters.doctorId!,
          if (filters.dateFrom != null) 'dateFrom': _dateFormat.format(filters.dateFrom!),
          if (filters.dateTo != null) 'dateTo': _dateFormat.format(filters.dateTo!),
          if (filters.weekday != null) 'weekday': filters.weekday!,
        },
      );
      return (response.data ?? const []).cast<Map<String, dynamic>>().map(_fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<AdminAppointment> getById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/admin/appointments/$id');
      return _fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<AdminAppointment> update(
    String id, {
    AppointmentStatus? status,
    DateTime? newDate,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/admin/appointments/$id',
        data: {
          if (status != null) 'status': status.name,
          if (newDate != null) 'date': _dateFormat.format(newDate),
        },
      );
      return _fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<AdminAppointment> createOnBehalf({
    required String userId,
    required String doctorId,
    required DateTime date,
    required String timeSlot,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/admin/appointments',
        data: {
          'userId': userId,
          'doctorId': doctorId,
          'date': _dateFormat.format(date),
          'timeSlot': timeSlot,
        },
      );
      return _fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  AdminAppointment _fromJson(Map<String, dynamic> json) => AdminAppointment(
    id: json['id'] as String,
    userId: json['userId'] as String,
    userName: json['userName'] as String,
    userPhone: json['userPhone'] as String,
    doctorId: json['doctorId'] as String,
    doctorName: json['doctorName'] as String,
    specialization: json['specialization'] as String,
    dateTime: DateTime.parse(json['dateTime'] as String),
    status: AppointmentStatus.values.byName(json['status'] as String),
    fee: json['fee'] as int,
    appointmentNumber: json['appointmentNumber'] as String?,
  );
}
