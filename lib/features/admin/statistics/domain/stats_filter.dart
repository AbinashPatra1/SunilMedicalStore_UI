import 'package:sunil_medical_store/features/admin/statistics/domain/stats_range.dart';

/// The active time-window selection for the Statistics dashboard — either
/// one of the fixed [StatsRange] presets (the pills), or a specific
/// historical period chosen via the "more filters" year/month picker.
sealed class StatsFilter {
  const StatsFilter();
}

class StatsRangeFilter extends StatsFilter {
  const StatsRangeFilter(this.range);

  final StatsRange range;
}

/// A specific year, optionally narrowed to one month within it.
class StatsPeriodFilter extends StatsFilter {
  const StatsPeriodFilter({required this.year, this.month});

  final int year;

  /// 1–12, or `null` for the whole year.
  final int? month;

  String get label => month == null ? '$year' : '${_monthNames[month! - 1]} $year';

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}
