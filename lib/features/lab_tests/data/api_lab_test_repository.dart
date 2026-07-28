import 'package:dio/dio.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/features/lab_tests/domain/lab_test.dart';
import 'package:sunil_medical_store/features/lab_tests/domain/lab_test_repository.dart';

/// [LabTestRepository] backed by the real catalog API.
class ApiLabTestRepository implements LabTestRepository {
  ApiLabTestRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<LabTest>> allTests() async {
    try {
      final response = await _dio.get<List<dynamic>>('/catalog/lab-tests');
      return (response.data ?? const []).cast<Map<String, dynamic>>().map(_fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<LabTest> testById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/catalog/lab-tests/$id');
      return _fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  LabTest _fromJson(Map<String, dynamic> json) => LabTest(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    labName: json['labName'] as String,
    price: json['price'] as int,
    mrp: json['mrp'] as int?,
    sampleType: json['sampleType'] as String,
    reportTime: json['reportTime'] as String,
    fastingRequired: json['fastingRequired'] as bool,
    parameters: ((json['parameters'] as List?) ?? const []).cast<String>(),
  );
}
