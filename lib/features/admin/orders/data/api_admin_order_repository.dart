import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/models/order.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/features/admin/orders/domain/admin_order.dart';
import 'package:sunil_medical_store/features/admin/orders/domain/admin_order_repository.dart';

/// [AdminOrderRepository] backed by `/v1/admin/orders`.
class ApiAdminOrderRepository implements AdminOrderRepository {
  ApiAdminOrderRepository(this._dio);

  final Dio _dio;
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  Future<List<AdminOrder>> list(OrderFilters filters) async {
    final search = filters.search?.trim();
    try {
      final response = await _dio.get<List<dynamic>>(
        '/admin/orders',
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
  Future<AdminOrder> getById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/admin/orders/$id');
      return _fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<AdminOrder> updateStatus(String id, OrderStatus status) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/admin/orders/$id',
        data: {'status': status.name},
      );
      return _fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  AdminOrder _fromJson(Map<String, dynamic> json) => AdminOrder(
    id: json['id'] as String,
    orderNumber: json['orderNumber'] as String,
    userId: json['userId'] as String,
    userName: json['userName'] as String,
    userPhone: json['userPhone'] as String,
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
}
