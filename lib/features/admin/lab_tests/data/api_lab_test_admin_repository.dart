import 'package:dio/dio.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/features/admin/lab_tests/domain/lab_test_admin_repository.dart';
import 'package:sunil_medical_store/features/lab_tests/domain/lab_test.dart';

/// [LabTestAdminRepository] backed by `/v1/admin/lab-tests`. See
/// `docs/API_ENDPOINTS.md` §Admin — Lab Tests.
class ApiLabTestAdminRepository implements LabTestAdminRepository {
  ApiLabTestAdminRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<LabTest>> list() async {
    try {
      final response = await _dio.get<List<dynamic>>('/admin/lab-tests');
      return (response.data ?? const []).cast<Map<String, dynamic>>().map(_fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<LabTest> getById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/admin/lab-tests/$id');
      return _fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<LabTest> create(LabTestInput input) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/admin/lab-tests',
        data: _toJson(input),
      );
      return _fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<LabTest> update(String id, LabTestInput input) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/admin/lab-tests/$id',
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
      await _dio.delete<void>('/admin/lab-tests/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Map<String, dynamic> _toJson(LabTestInput input) => {
    'name': input.name,
    'description': input.description,
    'labName': input.labName,
    'price': input.price,
    'mrp': ?input.mrp,
    'sampleType': input.sampleType,
    'reportTime': input.reportTime,
    'fastingRequired': input.fastingRequired,
    'parameters': input.parameters,
    'tags': input.tags,
  };

  LabTest _fromJson(Map<String, dynamic> json) => LabTest(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    labName: json['labName'] as String,
    price: json['price'] as int,
    mrp: json['mrp'] as int?,
    sampleType: json['sampleType'] as String,
    reportTime: json['reportTime'] as String,
    fastingRequired: json['fastingRequired'] as bool? ?? false,
    parameters: ((json['parameters'] as List?) ?? const []).cast<String>(),
    tags: ((json['tags'] as List?) ?? const []).cast<String>(),
  );
}
