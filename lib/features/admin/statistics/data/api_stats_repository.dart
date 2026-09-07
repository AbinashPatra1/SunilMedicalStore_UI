import 'package:dio/dio.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/features/admin/statistics/domain/admin_stats.dart';
import 'package:sunil_medical_store/features/admin/statistics/domain/stats_filter.dart';
import 'package:sunil_medical_store/features/admin/statistics/domain/stats_repository.dart';

/// [StatsRepository] backed by `/v1/admin/stats`.
class ApiStatsRepository implements StatsRepository {
  ApiStatsRepository(this._dio);

  final Dio _dio;

  @override
  Future<AdminStats> getStats(StatsFilter filter) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/stats',
        queryParameters: switch (filter) {
          StatsRangeFilter(:final range) => {'range': range.wireValue},
          StatsPeriodFilter(:final year, :final month) => {
            'range': 'custom',
            'year': '$year',
            if (month != null) 'month': '$month',
          },
        },
      );
      return _fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  AdminStats _fromJson(Map<String, dynamic> json) => AdminStats(
    revenue: _revenueFromJson(json['revenue'] as Map<String, dynamic>),
    topProducts: ((json['topProducts'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(_topProductFromJson)
        .toList(),
    lowStock: ((json['lowStock'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(_lowStockFromJson)
        .toList(),
    appointments: _bookingStatsFromJson(json['appointments'] as Map<String, dynamic>),
    labTests: _bookingStatsFromJson(json['labTests'] as Map<String, dynamic>),
  );

  RevenueStats _revenueFromJson(Map<String, dynamic> json) => RevenueStats(
    total: json['total'] as int,
    orderCount: json['orderCount'] as int,
    byStatus: ((json['byStatus'] as Map?) ?? const {}).cast<String, int>(),
    series: ((json['series'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(
          (i) => RevenueSeriesPoint(
            label: i['label'] as String,
            revenue: i['revenue'] as int,
            orderCount: i['orderCount'] as int,
          ),
        )
        .toList(),
  );

  TopProduct _topProductFromJson(Map<String, dynamic> json) => TopProduct(
    productId: json['productId'] as String,
    name: json['name'] as String,
    quantitySold: json['quantitySold'] as int,
    revenue: json['revenue'] as int,
  );

  LowStockProduct _lowStockFromJson(Map<String, dynamic> json) => LowStockProduct(
    productId: json['productId'] as String,
    name: json['name'] as String,
    stock: json['stock'] as int,
  );

  BookingStats _bookingStatsFromJson(Map<String, dynamic> json) => BookingStats(
    total: json['total'] as int,
    byStatus: ((json['byStatus'] as Map?) ?? const {}).cast<String, int>(),
  );
}
