import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/models/order.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/features/profile/domain/customer_profile.dart';
import 'package:sunil_medical_store/features/profile/domain/lab_test.dart';
import 'package:sunil_medical_store/features/profile/domain/past_appointment.dart';
import 'package:sunil_medical_store/features/profile/domain/profile_repository.dart';

/// [ProfileRepository] backed by the real API.
///
/// [customerProfile] self-heals a missing backend user row: if `GET
/// /users/me` 404s with `user_not_found` (e.g. a session that predates the
/// bootstrap call, or the bootstrap call failed silently), it upserts using
/// the Firebase display name and retries once, rather than surfacing the
/// error to the UI.
class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository(this._dio);

  final Dio _dio;
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  Future<CustomerProfile> customerProfile() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/users/me');
      return _profileFromJson(response.data!);
    } on DioException catch (e) {
      final error = ApiException.fromDioException(e);
      if (error.code != 'user_not_found') throw error;

      await upsertProfile(fullName: FirebaseAuth.instance.currentUser?.displayName);
      final retry = await _dio.get<Map<String, dynamic>>('/users/me');
      return _profileFromJson(retry.data!);
    }
  }

  @override
  Future<CustomerProfile> upsertProfile({
    String? fullName,
    String? email,
    Gender? gender,
    DateTime? dateOfBirth,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/users/me',
        data: {
          'fullName': ?fullName,
          'email': ?email,
          if (gender != null) 'gender': gender.name,
          if (dateOfBirth != null) 'dateOfBirth': _dateFormat.format(dateOfBirth),
        },
      );
      return _profileFromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<List<PastAppointment>> pastAppointments() =>
      _getList('/appointments/me', _appointmentFromJson);

  @override
  Future<List<Order>> pastOrders() => _getList('/orders', _orderFromJson);

  @override
  Future<List<LabTest>> labTests() => _getList('/lab-test-bookings', _labTestFromJson);

  @override
  Future<Order> orderById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/orders/$id');
      return _orderFromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<String> orderInvoiceUrl(String orderId) => _invoiceUrl('/orders/$orderId/invoice');

  @override
  Future<String> labTestInvoiceUrl(String labTestId) =>
      _invoiceUrl('/lab-test-bookings/$labTestId/invoice');

  Future<String> _invoiceUrl(String path) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(path);
      return response.data!['invoiceUrl'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<T>> _getList<T>(String path, T Function(Map<String, dynamic>) fromJson) async {
    try {
      final response = await _dio.get<List<dynamic>>(path);
      return (response.data ?? const []).cast<Map<String, dynamic>>().map(fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  CustomerProfile _profileFromJson(Map<String, dynamic> json) => CustomerProfile(
    fullName: json['fullName'] as String,
    phoneNumber: json['phoneNumber'] as String,
    email: json['email'] as String?,
    gender: json['gender'] == null ? null : Gender.values.byName(json['gender'] as String),
    dateOfBirth: json['dateOfBirth'] == null
        ? null
        : DateTime.parse(json['dateOfBirth'] as String),
    medicalRecords: ((json['medicalRecords'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(_medicalRecordFromJson)
        .toList(),
  );

  MedicalRecord _medicalRecordFromJson(Map<String, dynamic> json) => MedicalRecord(
    id: json['id'] as String,
    title: json['title'] as String,
    type: json['type'] as String,
    date: DateTime.parse(json['date'] as String),
  );

  PastAppointment _appointmentFromJson(Map<String, dynamic> json) => PastAppointment(
    id: json['id'] as String,
    doctorName: json['doctorName'] as String,
    specialization: json['specialization'] as String,
    dateTime: DateTime.parse(json['dateTime'] as String),
    status: AppointmentStatus.values.byName(json['status'] as String),
    fee: json['fee'] as int,
    myRating: json['myRating'] as int?,
  );

  Order _orderFromJson(Map<String, dynamic> json) => Order(
    id: json['id'] as String,
    orderNumber: json['orderNumber'] as String,
    placedOn: DateTime.parse(json['placedOn'] as String),
    status: OrderStatus.values.byName(json['status'] as String),
    items: ((json['items'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(
          (i) => OrderItem(
            name: i['name'] as String,
            quantity: i['quantity'] as int,
            price: i['price'] as int,
          ),
        )
        .toList(),
    subtotal: json['subtotal'] as int,
    discount: json['discount'] as int,
    delivery: json['delivery'] as int,
    total: json['total'] as int,
    paymentMethod: json['paymentMethod'] as String?,
    addressId: json['addressId'] as String?,
  );

  LabTest _labTestFromJson(Map<String, dynamic> json) => LabTest(
    id: json['id'] as String,
    name: json['name'] as String,
    labName: json['labName'] as String,
    bookedOn: DateTime.parse(json['bookedOn'] as String),
    status: LabTestStatus.values.byName(json['status'] as String),
    amount: json['amount'] as int,
    parameters: ((json['parameters'] as List?) ?? const []).cast<String>(),
    timeSlot: json['timeSlot'] as String?,
  );
}
