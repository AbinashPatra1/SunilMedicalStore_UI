import 'package:sunil_medical_store/features/profile/domain/customer_profile.dart';
import 'package:sunil_medical_store/features/profile/domain/lab_test.dart';
import 'package:sunil_medical_store/features/profile/domain/order.dart';
import 'package:sunil_medical_store/features/profile/domain/past_appointment.dart';
import 'package:sunil_medical_store/features/profile/domain/profile_repository.dart';

/// In-memory mock of [ProfileRepository] used until the backend exists.
class MockProfileRepository implements ProfileRepository {
  static const _delay = Duration(milliseconds: 600);

  @override
  Future<CustomerProfile> customerProfile() async {
    await Future<void>.delayed(_delay);
    return CustomerProfile(
      fullName: 'Rahul Kumar',
      gender: Gender.male,
      dateOfBirth: DateTime(1994, 3, 18),
      phoneNumber: '+91 81234 56789',
      email: 'rahul.kumar@example.com',
      medicalRecords: [
        MedicalRecord(title: 'Penicillin allergy', type: 'Allergy', date: DateTime(2021, 6, 12)),
        MedicalRecord(title: 'Type 2 Diabetes', type: 'Condition', date: DateTime(2022, 1, 5)),
        MedicalRecord(title: 'Lipid Profile report', type: 'Report', date: DateTime(2026, 5, 20)),
      ],
    );
  }

  @override
  Future<List<PastAppointment>> pastAppointments() async {
    await Future<void>.delayed(_delay);
    return [
      PastAppointment(id: 'a1', doctorName: 'Dr. Ananya Sharma', specialization: 'General Physician', dateTime: DateTime(2026, 7, 10, 11, 0), status: AppointmentStatus.completed, fee: 400),
      PastAppointment(id: 'a2', doctorName: 'Dr. Meera Iyer', specialization: 'Dermatologist', dateTime: DateTime(2026, 6, 22, 12, 30), status: AppointmentStatus.completed, fee: 700),
      PastAppointment(id: 'a3', doctorName: 'Dr. Rahul Verma', specialization: 'Pediatrician', dateTime: DateTime(2026, 6, 3, 18, 0), status: AppointmentStatus.cancelled, fee: 500),
    ];
  }

  @override
  Future<List<Order>> pastOrders() async {
    await Future<void>.delayed(_delay);
    return [
      Order(
        id: 'o1',
        orderNumber: 'SMS-100238',
        placedOn: DateTime(2026, 7, 18),
        status: OrderStatus.delivered,
        items: const [
          OrderItem(name: 'Paracetamol 500mg Tablets', quantity: 2, price: 30),
          OrderItem(name: 'Vitamin C 1000mg', quantity: 1, price: 250),
        ],
      ),
      Order(
        id: 'o2',
        orderNumber: 'SMS-100215',
        placedOn: DateTime(2026, 7, 2),
        status: OrderStatus.delivered,
        items: const [
          OrderItem(name: 'Digital Thermometer', quantity: 1, price: 200),
        ],
      ),
      Order(
        id: 'o3',
        orderNumber: 'SMS-100190',
        placedOn: DateTime(2026, 6, 15),
        status: OrderStatus.cancelled,
        items: const [
          OrderItem(name: 'Sunscreen SPF 50', quantity: 1, price: 350),
          OrderItem(name: 'Hand Sanitizer 500ml', quantity: 3, price: 150),
        ],
      ),
    ];
  }

  @override
  Future<List<LabTest>> labTests() async {
    await Future<void>.delayed(_delay);
    return [
      LabTest(id: 'l1', name: 'Complete Blood Count (CBC)', labName: 'Sunil Diagnostics', bookedOn: DateTime(2026, 7, 12), status: LabTestStatus.completed, amount: 450, parameters: const ['Hemoglobin', 'WBC count', 'Platelet count', 'RBC count']),
      LabTest(id: 'l2', name: 'Lipid Profile', labName: 'Sunil Diagnostics', bookedOn: DateTime(2026, 5, 20), status: LabTestStatus.completed, amount: 700, parameters: const ['Total Cholesterol', 'HDL', 'LDL', 'Triglycerides']),
      LabTest(id: 'l3', name: 'Thyroid Profile (T3, T4, TSH)', labName: 'City Path Labs', bookedOn: DateTime(2026, 7, 28), status: LabTestStatus.scheduled, amount: 600, parameters: const ['T3', 'T4', 'TSH']),
    ];
  }
}
