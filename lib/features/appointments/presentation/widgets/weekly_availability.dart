import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/core/utils/week_range.dart';

/// A row of seven day cells (Mon–Sun) for the current week, highlighting the
/// weekdays a doctor is available on.
class WeeklyAvailability extends StatelessWidget {
  const WeeklyAvailability({
    super.key,
    required this.week,
    required this.availableWeekdays,
  });

  final WeekRange week;
  final List<int> availableWeekdays;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final day in week.days)
          Expanded(
            child: _DayCell(
              day: day,
              available: availableWeekdays.contains(day.weekday),
            ),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.available});

  final DateTime day;
  final bool available;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = available
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);
    final fg = available
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingSm),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
      ),
      child: Column(
        children: [
          Text(
            DateFormat('EEE').format(day).substring(0, 1),
            style: theme.textTheme.labelSmall?.copyWith(color: fg),
          ),
          const SizedBox(height: 2),
          Text(
            '${day.day}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: fg,
              fontWeight: available ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
