import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_client.dart';
import 'package:sunil_medical_store/features/admin/statistics/data/api_stats_repository.dart';
import 'package:sunil_medical_store/features/admin/statistics/domain/admin_stats.dart';
import 'package:sunil_medical_store/features/admin/statistics/domain/stats_filter.dart';
import 'package:sunil_medical_store/features/admin/statistics/domain/stats_range.dart';
import 'package:sunil_medical_store/features/admin/statistics/domain/stats_repository.dart';

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return ApiStatsRepository(ref.watch(dioProvider));
});

/// Currently-selected time window for the Statistics dashboard — either a
/// fixed [StatsRange] preset or a custom [StatsPeriodFilter] year/month.
final statsFilterProvider = NotifierProvider<StatsFilterController, StatsFilter>(StatsFilterController.new);

class StatsFilterController extends Notifier<StatsFilter> {
  @override
  StatsFilter build() => const StatsRangeFilter(StatsRange.sevenDays);

  void setRange(StatsRange range) => state = StatsRangeFilter(range);

  void setPeriod({required int year, int? month}) => state = StatsPeriodFilter(year: year, month: month);
}

/// Aggregate stats for the currently-selected filter.
final adminStatsProvider = FutureProvider<AdminStats>((ref) {
  final filter = ref.watch(statsFilterProvider);
  return ref.watch(statsRepositoryProvider).getStats(filter);
});
