import 'package:dio/dio.dart';
import 'package:sunil_medical_store/core/models/order.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/features/cart/domain/cart_item.dart';
import 'package:sunil_medical_store/features/cart/domain/order_repository.dart';

/// [OrderRepository] backed by the real API.
class ApiOrderRepository implements OrderRepository {
  ApiOrderRepository(this._dio);

  final Dio _dio;

  @override
  Future<Order> placeOrder({
    required List<OrderRequestItem> items,
    required String addressId,
    String? promoCode,
    required String paymentMethod,
    String? upiId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/orders',
        data: {
          'items': [
            for (final item in items)
              {
                'kind': item.kind.name,
                if (item.kind == CartItemKind.medicine) 'productId': item.catalogId,
                if (item.kind == CartItemKind.labTest) 'testId': item.catalogId,
                'quantity': item.quantity,
              },
          ],
          'addressId': addressId,
          'promoCode': ?promoCode,
          'paymentMethod': paymentMethod,
          'upiId': ?upiId,
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
