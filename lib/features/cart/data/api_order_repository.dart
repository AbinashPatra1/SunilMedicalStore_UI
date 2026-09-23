import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/models/order.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/features/cart/domain/cart_item.dart';
import 'package:sunil_medical_store/features/cart/domain/order_repository.dart';
import 'package:sunil_medical_store/features/cart/domain/razorpay_order_details.dart';

/// [OrderRepository] backed by the real API.
class ApiOrderRepository implements OrderRepository {
  ApiOrderRepository(this._dio);

  final Dio _dio;
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  Future<Order> placeOrder({
    required List<OrderRequestItem> items,
    required String addressId,
    String? promoCode,
    required String paymentMethod,
    String? prescriptionId,
    String? razorpayOrderId,
    String? razorpayPaymentId,
    String? razorpaySignature,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/orders',
        data: {
          'items': _itemsToJson(items),
          'addressId': addressId,
          'promoCode': ?promoCode,
          'paymentMethod': paymentMethod,
          'prescriptionId': ?prescriptionId,
          'razorpayOrderId': ?razorpayOrderId,
          'razorpayPaymentId': ?razorpayPaymentId,
          'razorpaySignature': ?razorpaySignature,
        },
      );
      return _fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<RazorpayOrderDetails> createRazorpayOrder({
    required List<OrderRequestItem> items,
    required String addressId,
    String? promoCode,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/payments/razorpay/order',
        data: {
          'items': _itemsToJson(items),
          'addressId': addressId,
          'promoCode': ?promoCode,
        },
      );
      final json = response.data!;
      return RazorpayOrderDetails(
        razorpayOrderId: json['razorpayOrderId'] as String,
        amount: json['amount'] as int,
        currency: json['currency'] as String,
        keyId: json['keyId'] as String,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  List<Map<String, dynamic>> _itemsToJson(List<OrderRequestItem> items) => [
    for (final item in items)
      {
        'kind': item.kind.name,
        if (item.kind == CartItemKind.medicine) 'productId': item.catalogId,
        if (item.kind == CartItemKind.labTest) 'testId': item.catalogId,
        'quantity': item.quantity,
        if (item.kind == CartItemKind.labTest && item.scheduledDate != null)
          'scheduledDate': _dateFormat.format(item.scheduledDate!),
        if (item.kind == CartItemKind.labTest && item.timeSlot != null) 'timeSlot': item.timeSlot,
      },
  ];

  @override
  Future<Order> cancelOrder(String id) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>('/orders/$id/cancel');
      return _fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<Order> requestReturn(String id, {required List<ReturnLine> lines, required String reason}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/orders/$id/return',
        data: {
          'items': [
            for (final l in lines) {'productId': l.productId, 'quantity': l.quantity},
          ],
          'reason': reason,
        },
      );
      return _fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Order _fromJson(Map<String, dynamic> json) => Order(
    id: json['id'] as String,
    orderNumber: json['orderNumber'] as String,
    placedOn: DateTime.parse(json['placedOn'] as String),
    status: OrderStatus.fromWire(json['status'] as String?),
    items: OrderItem.listFromJson(json['items']),
    subtotal: json['subtotal'] as int,
    discount: json['discount'] as int,
    delivery: json['delivery'] as int,
    total: json['total'] as int,
    paymentMethod: json['paymentMethod'] as String?,
    addressId: json['addressId'] as String?,
    refundStatus: RefundStatus.fromWire(json['refundStatus'] as String?),
    platformFee: json['platformFee'] as int? ?? 0,
    deliveredOn: DateTime.tryParse(json['deliveredOn'] as String? ?? ''),
    deliveryAddress: OrderAddress.tryParse(json['deliveryAddress']),
    statusHistory: OrderStatusEvent.listFromJson(json['statusHistory']),
    returnRequest: OrderReturn.tryParse(json['returnRequest']),
  );
}
