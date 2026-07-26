import 'package:sunil_medical_store/features/lab_tests/domain/lab_test.dart';
import 'package:sunil_medical_store/features/lab_tests/domain/lab_test_repository.dart';

/// In-memory mock of [LabTestRepository] with a fixed catalog.
class MockLabTestRepository implements LabTestRepository {
  @override
  Future<List<LabTest>> allTests() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return const [
      LabTest(
        id: 'lt1',
        name: 'Complete Blood Count (CBC)',
        description: 'Screens overall blood health and helps detect infections and anemia.',
        labName: 'Sunil Diagnostics',
        price: 450,
        mrp: 600,
        sampleType: 'Blood',
        reportTime: 'Within 24 hours',
        fastingRequired: false,
        parameters: ['Hemoglobin', 'WBC count', 'RBC count', 'Platelet count', 'Hematocrit'],
      ),
      LabTest(
        id: 'lt2',
        name: 'Lipid Profile',
        description: 'Measures cholesterol and triglycerides to assess heart health.',
        labName: 'Sunil Diagnostics',
        price: 700,
        mrp: 900,
        sampleType: 'Blood',
        reportTime: 'Within 24 hours',
        fastingRequired: true,
        parameters: ['Total Cholesterol', 'HDL', 'LDL', 'Triglycerides', 'VLDL'],
      ),
      LabTest(
        id: 'lt3',
        name: 'Thyroid Profile (T3, T4, TSH)',
        description: 'Checks thyroid gland function.',
        labName: 'City Path Labs',
        price: 600,
        mrp: 800,
        sampleType: 'Blood',
        reportTime: 'Within 24 hours',
        fastingRequired: false,
        parameters: ['T3', 'T4', 'TSH'],
      ),
      LabTest(
        id: 'lt4',
        name: 'HbA1c (Diabetes)',
        description: 'Shows average blood sugar over the last 3 months.',
        labName: 'Sunil Diagnostics',
        price: 500,
        mrp: 650,
        sampleType: 'Blood',
        reportTime: 'Within 24 hours',
        fastingRequired: false,
        parameters: ['HbA1c', 'Estimated Average Glucose'],
      ),
      LabTest(
        id: 'lt5',
        name: 'Liver Function Test (LFT)',
        description: 'Assesses how well the liver is working.',
        labName: 'City Path Labs',
        price: 750,
        mrp: 950,
        sampleType: 'Blood',
        reportTime: 'Within 24 hours',
        fastingRequired: true,
        parameters: ['Bilirubin', 'SGOT', 'SGPT', 'ALP', 'Albumin', 'Total Protein'],
      ),
      LabTest(
        id: 'lt6',
        name: 'Vitamin D (25-OH)',
        description: 'Detects vitamin D deficiency.',
        labName: 'Sunil Diagnostics',
        price: 1200,
        mrp: 1500,
        sampleType: 'Blood',
        reportTime: 'Within 48 hours',
        fastingRequired: false,
        parameters: ['25-Hydroxy Vitamin D'],
      ),
      LabTest(
        id: 'lt7',
        name: 'Full Body Health Checkup',
        description: 'A comprehensive package covering 60+ parameters across major organs.',
        labName: 'Sunil Diagnostics',
        price: 1999,
        mrp: 3000,
        sampleType: 'Blood & Urine',
        reportTime: 'Within 48 hours',
        fastingRequired: true,
        parameters: ['CBC', 'Lipid Profile', 'Liver Function', 'Kidney Function', 'Thyroid', 'Blood Sugar', 'Urine Routine'],
      ),
    ];
  }
}
