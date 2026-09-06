import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/models/order.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/admin/presentation/widgets/admin_sign_out_button.dart';
import 'package:sunil_medical_store/features/admin/statistics/domain/admin_stats.dart';
import 'package:sunil_medical_store/features/admin/statistics/domain/stats_range.dart';
import 'package:sunil_medical_store/features/admin/statistics/presentation/providers/stats_providers.dart';
import 'package:sunil_medical_store/features/admin/statistics/presentation/widgets/revenue_line_chart.dart';
import 'package:sunil_medical_store/features/admin/statistics/presentation/widgets/stat_tile.dart';
import 'package:sunil_medical_store/features/admin/statistics/presentation/widgets/status_bar_chart.dart';
import 'package:sunil_medical_store/features/admin/inventory/presentation/widgets/stock_badge.dart';
import 'package:sunil_medical_store/features/profile/domain/lab_test.dart';
import 'package:sunil_medical_store/features/profile/domain/past_appointment.dart';

/// Admin > Statistics: revenue trend, order/appointment/lab-test status
/// breakdowns, top-selling products, and low-stock alerts — all scoped to a
/// selectable [StatsRange].
class AdminStatisticsScreen extends ConsumerWidget {
  const AdminStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final range = ref.watch(statsRangeProvider);
    final async = ref.watch(adminStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        actions: const [AdminSignOutButton()],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingLg,
              vertical: AppConstants.spacingSm,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final r in StatsRange.values) ...[
                    ChoiceChip(
                      label: Text(r.label),
                      selected: range == r,
                      onSelected: (_) => ref.read(statsRangeProvider.notifier).set(r),
                    ),
                    const SizedBox(width: AppConstants.spacingSm),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(error is ApiException ? error.message : 'Could not load statistics.'),
                    const SizedBox(height: AppConstants.spacingSm),
                    TextButton(
                      onPressed: () => ref.invalidate(adminStatsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (stats) => RefreshIndicator(
                onRefresh: () async => ref.invalidate(adminStatsProvider),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppConstants.spacingLg,
                    0,
                    AppConstants.spacingLg,
                    AppConstants.spacingXl,
                  ),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: StatTile(
                            label: 'Revenue',
                            value: '₹${stats.revenue.total}',
                            icon: Icons.payments_outlined,
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacingMd),
                        Expanded(
                          child: StatTile(
                            label: 'Orders',
                            value: '${stats.revenue.orderCount}',
                            icon: Icons.receipt_long_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingLg),
                    Text('Revenue trend', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppConstants.spacingSm),
                    SizedBox(height: 220, child: RevenueLineChart(series: stats.revenue.series)),
                    const SizedBox(height: AppConstants.spacingLg),
                    Text('Orders by status', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppConstants.spacingSm),
                    SizedBox(
                      height: 200,
                      child: StatusBarChart(entries: _orderStatusEntries(stats.revenue.byStatus)),
                    ),
                    const Divider(height: AppConstants.spacingXxl),
                    Text('Top-selling products', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppConstants.spacingSm),
                    if (stats.topProducts.isEmpty)
                      Text(
                        'No sales in this period.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      )
                    else
                      Card(
                        child: Column(
                          children: [
                            for (var i = 0; i < stats.topProducts.length; i++) ...[
                              if (i > 0) const Divider(height: 1),
                              _TopProductRow(rank: i + 1, product: stats.topProducts[i]),
                            ],
                          ],
                        ),
                      ),
                    const Divider(height: AppConstants.spacingXxl),
                    Text('Low stock', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppConstants.spacingSm),
                    if (stats.lowStock.isEmpty)
                      Text(
                        'Nothing low on stock.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      )
                    else
                      Card(
                        child: Column(
                          children: [
                            for (var i = 0; i < stats.lowStock.length; i++) ...[
                              if (i > 0) const Divider(height: 1),
                              ListTile(
                                title: Text(stats.lowStock[i].name),
                                trailing: StockBadge(stock: stats.lowStock[i].stock),
                              ),
                            ],
                          ],
                        ),
                      ),
                    const Divider(height: AppConstants.spacingXxl),
                    Row(
                      children: [
                        Expanded(
                          child: StatTile(
                            label: 'Appointments',
                            value: '${stats.appointments.total}',
                            icon: Icons.calendar_month_outlined,
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacingMd),
                        Expanded(
                          child: StatTile(
                            label: 'Lab tests',
                            value: '${stats.labTests.total}',
                            icon: Icons.science_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingLg),
                    Text('Appointments by status', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppConstants.spacingSm),
                    SizedBox(
                      height: 180,
                      child: StatusBarChart(entries: _appointmentStatusEntries(stats.appointments.byStatus)),
                    ),
                    const SizedBox(height: AppConstants.spacingLg),
                    Text('Lab tests by status', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppConstants.spacingSm),
                    SizedBox(
                      height: 180,
                      child: StatusBarChart(entries: _labTestStatusEntries(stats.labTests.byStatus)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<StatusBarEntry> _orderStatusEntries(Map<String, int> byStatus) => [
    for (final status in OrderStatus.values)
      StatusBarEntry(
        label: status.label,
        value: byStatus[status.name] ?? 0,
        color: switch (status) {
          OrderStatus.created => Colors.blueGrey,
          OrderStatus.processing => Colors.amber,
          OrderStatus.shipped => Colors.indigo,
          OrderStatus.delivered => Colors.green,
          OrderStatus.cancelled => Colors.red,
        },
      ),
  ];

  List<StatusBarEntry> _appointmentStatusEntries(Map<String, int> byStatus) => [
    for (final status in AppointmentStatus.values)
      StatusBarEntry(
        label: status.label,
        value: byStatus[status.name] ?? 0,
        color: switch (status) {
          AppointmentStatus.upcoming => Colors.indigo,
          AppointmentStatus.completed => Colors.green,
          AppointmentStatus.cancelled => Colors.red,
        },
      ),
  ];

  List<StatusBarEntry> _labTestStatusEntries(Map<String, int> byStatus) => [
    for (final status in LabTestStatus.values)
      StatusBarEntry(
        label: status.label,
        value: byStatus[status.name] ?? 0,
        color: switch (status) {
          LabTestStatus.scheduled => Colors.indigo,
          LabTestStatus.completed => Colors.green,
          LabTestStatus.cancelled => Colors.red,
        },
      ),
  ];
}

class _TopProductRow extends StatelessWidget {
  const _TopProductRow({required this.rank, required this.product});

  final int rank;
  final TopProduct product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text('$rank', style: TextStyle(color: theme.colorScheme.onPrimaryContainer)),
      ),
      title: Text(product.name),
      subtitle: Text('${product.quantitySold} sold'),
      trailing: Text('₹${product.revenue}', style: theme.textTheme.titleSmall),
    );
  }
}
