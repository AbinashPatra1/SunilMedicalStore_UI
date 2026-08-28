import 'package:dio/dio.dart';
import 'package:sunil_medical_store/core/models/prescription.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/features/admin/orders/domain/admin_prescription.dart';
import 'package:sunil_medical_store/features/admin/orders/domain/admin_prescription_repository.dart';

/// [AdminPrescriptionRepository] backed by `/v1/admin/prescriptions`.
class ApiAdminPrescriptionRepository implements AdminPrescriptionRepository {
  ApiAdminPrescriptionRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<AdminPrescription>> list({PrescriptionStatus? status}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/admin/prescriptions',
        queryParameters: {if (status != null) 'status': status.name},
      );
      return (response.data ?? const []).cast<Map<String, dynamic>>().map(_fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<AdminPrescription> getById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/admin/prescriptions/$id');
      return _fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<AdminPrescription> review(
    String id, {
    required PrescriptionStatus status,
    String? note,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/admin/prescriptions/$id',
        data: {'status': status.name, 'note': ?note},
      );
      return _fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  AdminPrescription _fromJson(Map<String, dynamic> json) => AdminPrescription(
    id: json['id'] as String,
    userId: json['userId'] as String,
    userName: json['userName'] as String,
    userPhone: json['userPhone'] as String,
    imageUrl: json['imageUrl'] as String,
    uploadedOn: DateTime.parse(json['uploadedOn'] as String),
    status: PrescriptionStatus.values.byName(json['status'] as String),
    note: json['note'] as String?,
  );
}
