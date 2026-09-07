import 'package:sunil_medical_store/features/admin/statistics/domain/admin_stats.dart';
import 'package:sunil_medical_store/features/admin/statistics/domain/stats_filter.dart';

/// Read-only aggregate stats for the admin Statistics dashboard.
abstract interface class StatsRepository {
  Future<AdminStats> getStats(StatsFilter filter);
}
