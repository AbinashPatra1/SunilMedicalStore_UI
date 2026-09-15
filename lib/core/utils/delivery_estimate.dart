import 'package:intl/intl.dart';

/// A friendly, client-computed delivery estimate, e.g. `Get by Fri, 18th
/// Sept`. There's no real delivery-estimation system yet (no logistics
/// data to base one on) — this is a fixed number of days out, purely for
/// display on the catalog cards.
String deliveryEstimateLabel({int daysFromNow = 3}) {
  final date = DateTime.now().add(Duration(days: daysFromNow));
  final weekday = DateFormat('EEE').format(date);
  final month = DateFormat('MMM').format(date);
  return 'Get by $weekday, ${date.day}${_ordinalSuffix(date.day)} $month';
}

String _ordinalSuffix(int day) {
  if (day >= 11 && day <= 13) return 'th';
  switch (day % 10) {
    case 1:
      return 'st';
    case 2:
      return 'nd';
    case 3:
      return 'rd';
    default:
      return 'th';
  }
}
