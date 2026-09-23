import 'package:sunil_medical_store/core/models/order.dart';

enum ReturnState {
  /// Returns are off, or the order was cancelled — show nothing.
  hidden,

  /// Not delivered yet (or delivery date unknown): only the policy applies.
  notStarted,

  /// Delivered and still inside the window; [ReturnInfo.date] is the last day.
  open,

  /// Delivered and past the window; [ReturnInfo.date] is the day it closed.
  closed,
}

class ReturnInfo {
  const ReturnInfo(this.state, {this.date, this.days = 0});

  final ReturnState state;
  final DateTime? date;
  final int days;
}

/// Where an order stands against the store's return policy. The window runs
/// [windowDays] days from the delivery date; comparisons are by calendar day.
ReturnInfo evaluateReturn({
  required OrderStatus status,
  required DateTime? deliveredOn,
  required bool returnsEnabled,
  required int windowDays,
  DateTime? now,
}) {
  if (!returnsEnabled ||
      status == OrderStatus.cancelled ||
      status == OrderStatus.returned ||
      status == OrderStatus.returnRequested) {
    return const ReturnInfo(ReturnState.hidden);
  }
  if (status != OrderStatus.delivered || deliveredOn == null) {
    return ReturnInfo(ReturnState.notStarted, days: windowDays);
  }
  final delivered = deliveredOn.toLocal();
  final lastDay = DateTime(delivered.year, delivered.month, delivered.day + windowDays);
  final today = now ?? DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  return ReturnInfo(
    todayDate.isAfter(lastDay) ? ReturnState.closed : ReturnState.open,
    date: lastDay,
    days: windowDays,
  );
}

/// One-line cancellation note for [status], or `null` when it doesn't apply
/// (delivered/cancelled orders).
String? cancelPolicyMessage(OrderStatus status) => switch (status) {
  OrderStatus.created || OrderStatus.processing => 'You can cancel this order until it is shipped.',
  OrderStatus.shipped => 'This order can no longer be cancelled.',
  _ => null,
};
