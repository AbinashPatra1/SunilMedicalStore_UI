import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sunil_medical_store/features/admin/statistics/domain/admin_stats.dart';

/// Revenue-over-time trend line for the selected [StatsRange] — bucket
/// granularity (hourly/daily/monthly) is chosen server-side; the client
/// just renders whatever labeled points come back.
class RevenueLineChart extends StatelessWidget {
  const RevenueLineChart({super.key, required this.series});

  final List<RevenueSeriesPoint> series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (series.isEmpty) {
      return Center(
        child: Text('No revenue in this period.', style: theme.textTheme.bodyMedium),
      );
    }

    final maxRevenue = series.map((p) => p.revenue).reduce((a, b) => a > b ? a : b);
    // Label every point when there are few, otherwise thin them out so the
    // axis doesn't turn into unreadable overlapping text.
    final labelStride = (series.length / 6).ceil().clamp(1, series.length);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxRevenue == 0 ? 10 : maxRevenue * 1.2,
        gridData: const FlGridData(drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index < 0 || index >= series.length || index % labelStride != 0) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(series[index].label, style: theme.textTheme.labelSmall),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((spot) {
              final point = series[spot.x.round()];
              return LineTooltipItem(
                '${point.label}\n₹${point.revenue}',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < series.length; i++) FlSpot(i.toDouble(), series[i].revenue.toDouble()),
            ],
            isCurved: true,
            color: theme.colorScheme.primary,
            barWidth: 3,
            dotData: FlDotData(show: series.length <= 14),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}
