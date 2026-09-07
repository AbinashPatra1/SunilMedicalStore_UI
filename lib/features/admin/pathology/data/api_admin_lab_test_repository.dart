import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/features/admin/pathology/domain/admin_lab_test_booking.dart';
import 'package:sunil_medical_store/features/admin/pathology/domain/admin_lab_test_repository.dart';
import 'package:sunil_medical_store/features/profile/domain/lab_test.dart';

/// [AdminLabTestRepository] backed by `/v1/admin/lab-test-bookings`.
class ApiAdminLabTestRepository implements AdminLabTestRepository {
  ApiAdminLabTestRepository(this._dio);

  final Dio _dio;
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  Future<List<AdminLabTestBooking>> list(LabTestBookingFilters filters) async {
    final search = filters.search?.trim();
    try {
      final response = await _dio.get<List<dynamic>>(
        '/admin/lab-test-bookings',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (filters.status != null) 'status': filters.status!.name,
          if (filters.dateFrom != null) 'dateFrom': _dateFormat.format(filters.dateFrom!),
          if (filters.dateTo != null) 'dateTo': _dateFormat.format(filters.dateTo!),
        },
      );
      return (response.data ?? const []).cast<Map<String, dynamic>>().map(_fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<AdminLabTestBooking> getById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/admin/lab-test-bookings/$id');
      return _fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<AdminLabTestBooking> updateStatus(String id, LabTestStatus status) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/admin/lab-test-bookings/$id',
        data: {'status': status.name},
      );
      return _fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  AdminLabTestBooking _fromJson(Map<String, dynamic> json) => AdminLabTestBooking(
    id: json['id'] as String,
    userId: json['userId'] as String,
    userName: json['userName'] as String,
    userPhone: json['userPhone'] as String,
    name: json['name'] as String,
    labName: json['labName'] as String,
    bookedOn: DateTime.parse(json['bookedOn'] as String),
    status: LabTestStatus.values.byName(json['status'] as String),
    amount: json['amount'] as int,
    parameters: ((json['parameters'] as List?) ?? const []).cast<String>(),
    timeSlot: json['timeSlot'] as String?,
    bookingNumber: json['bookingNumber'] as String?,
  );
}
