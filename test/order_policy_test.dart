import 'package:flutter_test/flutter_test.dart';
import 'package:sunil_medical_store/core/models/order.dart';
import 'package:sunil_medical_store/core/utils/order_policy.dart';

void main() {
  final delivered = DateTime(2026, 9, 10, 15, 30);

  ReturnInfo eval({
    OrderStatus status = OrderStatus.delivered,
    DateTime? deliveredOn,
    bool enabled = true,
    int days = 7,
    required DateTime now,
  }) => evaluateReturn(
    status: status,
    deliveredOn: deliveredOn ?? delivered,
    returnsEnabled: enabled,
    windowDays: days,
    now: now,
  );

  test('open through the last day, closed the day after', () {
    final onLastDay = eval(now: DateTime(2026, 9, 17, 23, 59));
    expect(onLastDay.state, ReturnState.open);
    expect(onLastDay.date, DateTime(2026, 9, 17));

    final after = eval(now: DateTime(2026, 9, 18, 0, 1));
    expect(after.state, ReturnState.closed);
    expect(after.date, DateTime(2026, 9, 17));
  });

  test('hidden when returns are off or the order is cancelled', () {
    expect(eval(enabled: false, now: delivered).state, ReturnState.hidden);
    expect(eval(status: OrderStatus.cancelled, now: delivered).state, ReturnState.hidden);
  });

  test('not started before delivery or when the delivery date is unknown', () {
    expect(eval(status: OrderStatus.shipped, now: delivered).state, ReturnState.notStarted);
    final noDate = evaluateReturn(
      status: OrderStatus.delivered,
      deliveredOn: null,
      returnsEnabled: true,
      windowDays: 7,
    );
    expect(noDate.state, ReturnState.notStarted);
    expect(noDate.days, 7);
  });

  test('cancel note only applies before delivery', () {
    expect(cancelPolicyMessage(OrderStatus.created), contains('can cancel'));
    expect(cancelPolicyMessage(OrderStatus.processing), contains('can cancel'));
    expect(cancelPolicyMessage(OrderStatus.shipped), contains('no longer'));
    expect(cancelPolicyMessage(OrderStatus.delivered), isNull);
    expect(cancelPolicyMessage(OrderStatus.cancelled), isNull);
  });

  test('customers can cancel Created and Processing orders only', () {
    expect(OrderStatus.created.isCustomerCancellable, isTrue);
    expect(OrderStatus.processing.isCustomerCancellable, isTrue);
    expect(OrderStatus.shipped.isCustomerCancellable, isFalse);
    expect(OrderStatus.delivered.isCustomerCancellable, isFalse);
  });

  test('admins can cancel until the order is delivered', () {
    expect(OrderStatus.shipped.isAdminCancellable, isTrue);
    expect(OrderStatus.delivered.isAdminCancellable, isFalse);
    expect(OrderStatus.cancelled.isAdminCancellable, isFalse);
    expect(OrderStatus.returned.isAdminCancellable, isFalse);
  });

  test('no return window once a return is requested or done', () {
    expect(eval(status: OrderStatus.returnRequested, now: delivered).state, ReturnState.hidden);
    expect(eval(status: OrderStatus.returned, now: delivered).state, ReturnState.hidden);
  });

  test('status history parses, sorts and tolerates junk', () {
    final events = OrderStatusEvent.listFromJson([
      {'status': 'delivered', 'at': '2026-09-05T10:00:00Z'},
      {'status': 'created', 'at': '2026-09-01T09:30:00Z'},
      {'status': 'processing'},
      'junk',
    ]);
    expect(events.map((e) => e.status), [OrderStatus.created, OrderStatus.delivered]);
    expect(OrderStatus.fromWire('nope'), OrderStatus.created);
  });
}
