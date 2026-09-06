import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// One bar in a [StatusBarChart] — a status label, its count, and the color
/// to render it in (callers pick semantic colors, e.g. green for
/// "delivered", red for "cancelled").
class StatusBarEntry {
  const StatusBarEntry({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;
}

/// Small categorical bar chart for a status breakdown (order status,
/// appointment status, lab-test status) — one bar per [StatusBarEntry].
class StatusBarChart extends StatelessWidget {
  const StatusBarChart({super.key, required this.entries});

  final List<StatusBarEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxValue = entries.map((e) => e.value).fold(0, (a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        maxY: maxValue == 0 ? 10 : maxValue * 1.2,
        gridData: const FlGridData(drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index < 0 || index >= entries.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(entries[index].label, style: theme.textTheme.labelSmall),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
              '${entries[group.x.toInt()].label}\n${rod.toY.round()}',
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < entries.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: entries[i].value.toDouble(),
                  color: entries[i].color,
                  width: 22,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
