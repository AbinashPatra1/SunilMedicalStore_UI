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
    expect(cancelPolicyMessage(OrderStatus.processing), contains('no longer'));
    expect(cancelPolicyMessage(OrderStatus.delivered), isNull);
    expect(cancelPolicyMessage(OrderStatus.cancelled), isNull);
  });

  test('only Created orders are customer-cancellable', () {
    expect(OrderStatus.created.isCustomerCancellable, isTrue);
    expect(OrderStatus.processing.isCustomerCancellable, isFalse);
  });
}
