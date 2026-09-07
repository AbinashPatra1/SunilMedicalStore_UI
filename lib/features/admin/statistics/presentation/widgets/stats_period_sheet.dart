import 'package:flutter/material.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/admin/statistics/domain/stats_filter.dart';

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// Bottom sheet: pick a specific year, optionally narrowed to one month
/// within it. Pops a `(year, month)` record on Apply — `month` is `null`
/// for "the whole year".
class StatsPeriodSheet extends StatefulWidget {
  const StatsPeriodSheet({super.key, this.initial});

  final StatsPeriodFilter? initial;

  @override
  State<StatsPeriodSheet> createState() => _StatsPeriodSheetState();
}

class _StatsPeriodSheetState extends State<StatsPeriodSheet> {
  late int _year = widget.initial?.year ?? DateTime.now().year;
  late int? _month = widget.initial?.month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentYear = DateTime.now().year;
    final years = [for (var y = currentYear; y >= currentYear - 4; y--) y];

    return Padding(
      padding: EdgeInsets.only(
        left: AppConstants.spacingLg,
        right: AppConstants.spacingLg,
        top: AppConstants.spacingLg,
        bottom: AppConstants.spacingLg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Custom period', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppConstants.spacingLg),
          Text('Year', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppConstants.spacingXs),
          DropdownButtonFormField<int>(
            initialValue: _year,
            items: [
              for (final y in years) DropdownMenuItem(value: y, child: Text('$y')),
            ],
            onChanged: (v) => setState(() => _year = v!),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Text('Month (optional)', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppConstants.spacingXs),
          DropdownButtonFormField<int?>(
            initialValue: _month,
            items: [
              const DropdownMenuItem(value: null, child: Text('Whole year')),
              for (var m = 1; m <= 12; m++) DropdownMenuItem(value: m, child: Text(_monthNames[m - 1])),
            ],
            onChanged: (v) => setState(() => _month = v),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop((_year, _month)),
              child: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }
}
