import 'package:sunil_medical_store/features/lab_tests/domain/lab_test.dart';

/// Reads the lab test catalog, implemented by the data layer.
abstract interface class LabTestRepository {
  Future<List<LabTest>> allTests();
}
