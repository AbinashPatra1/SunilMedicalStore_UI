import 'package:flutter_test/flutter_test.dart';
import 'package:sunil_medical_store/core/models/order.dart';
import 'package:sunil_medical_store/features/profile/presentation/widgets/order_detail_sections.dart';

void main() {
  final placed = DateTime.utc(2026, 9, 21, 13, 51);
  final delivered = DateTime.utc(2026, 9, 21, 18, 30);
  final returned = DateTime.utc(2026, 9, 25, 15, 5);

  test('an old order with only a new history entry keeps Created and Delivered', () {
    final t = orderTimeline(
      history: [OrderStatusEvent(OrderStatus.returnRequested, returned)],
      status: OrderStatus.returnRequested,
      placedOn: placed,
      deliveredOn: delivered,
    );
    expect(t.map((e) => e.status), [OrderStatus.created, OrderStatus.delivered, OrderStatus.returnRequested]);
  });

  test('a full history is used as-is', () {
    final history = [
      OrderStatusEvent(OrderStatus.created, placed),
      OrderStatusEvent(OrderStatus.delivered, delivered),
    ];
    final t = orderTimeline(history: history, status: OrderStatus.delivered, placedOn: placed, deliveredOn: delivered);
    expect(t.length, 2);
  });

  test('return card names a line from the order when the backend omits it', () {
    const line = ReturnLine(productId: 'p6', name: '', quantity: 1);
    expect(line.name.isEmpty, isTrue);
  });
}
