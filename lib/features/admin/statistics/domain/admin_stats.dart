/// One point on the revenue trend chart — a day/hour/month bucket, exact
/// granularity chosen server-side based on the requested [StatsRange].
class RevenueSeriesPoint {
  const RevenueSeriesPoint({required this.label, required this.revenue, required this.orderCount});

  /// Short axis label, e.g. `"Mon"`, `"12 Sep"`, `"Jan"` — pre-formatted by
  /// the backend so the client doesn't need to guess the bucket size.
  final String label;
  final int revenue;
  final int orderCount;
}

/// A single best-selling product over the period.
class TopProduct {
  const TopProduct({
    required this.productId,
    required this.name,
    required this.quantitySold,
    required this.revenue,
  });

  final String productId;
  final String name;
  final int quantitySold;
  final int revenue;
}

/// A product at or near zero stock, for the dashboard's restock callout.
class LowStockProduct {
  const LowStockProduct({required this.productId, required this.name, required this.stock});

  final String productId;
  final String name;
  final int stock;
}

/// Revenue + order counts over the period, plus a breakdown by
/// [OrderStatus] wire value and a trend series for the chart.
class RevenueStats {
  const RevenueStats({
    required this.total,
    required this.orderCount,
    required this.byStatus,
    required this.series,
  });

  final int total;
  final int orderCount;

  /// Keyed by the `OrderStatus` wire value (`created`, `processing`, …).
  final Map<String, int> byStatus;
  final List<RevenueSeriesPoint> series;
}

/// Booking counts over the period for appointments or lab tests, broken
/// down by their respective status wire values.
class BookingStats {
  const BookingStats({required this.total, required this.byStatus});

  final int total;
  final Map<String, int> byStatus;
}

/// Everything the admin Statistics dashboard shows for one [StatsRange].
class AdminStats {
  const AdminStats({
    required this.revenue,
    required this.topProducts,
    required this.lowStock,
    required this.appointments,
    required this.labTests,
  });

  final RevenueStats revenue;
  final List<TopProduct> topProducts;
  final List<LowStockProduct> lowStock;
  final BookingStats appointments;
  final BookingStats labTests;
}
