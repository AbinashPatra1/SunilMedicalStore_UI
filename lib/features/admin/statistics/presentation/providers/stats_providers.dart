import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_client.dart';
import 'package:sunil_medical_store/features/admin/statistics/data/api_stats_repository.dart';
import 'package:sunil_medical_store/features/admin/statistics/domain/admin_stats.dart';
import 'package:sunil_medical_store/features/admin/statistics/domain/stats_range.dart';
import 'package:sunil_medical_store/features/admin/statistics/domain/stats_repository.dart';

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return ApiStatsRepository(ref.watch(dioProvider));
});

/// Currently-selected time range for the Statistics dashboard.
final statsRangeProvider = NotifierProvider<StatsRangeNotifier, StatsRange>(StatsRangeNotifier.new);

class StatsRangeNotifier extends Notifier<StatsRange> {
  @override
  StatsRange build() => StatsRange.sevenDays;

  void set(StatsRange next) => state = next;
}

/// Aggregate stats for the currently-selected range.
final adminStatsProvider = FutureProvider<AdminStats>((ref) {
  final range = ref.watch(statsRangeProvider);
  return ref.watch(statsRepositoryProvider).getStats(range);
});
