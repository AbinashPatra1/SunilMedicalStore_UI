import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/lab_tests/domain/lab_test_slots.dart';

/// Bottom sheet: pick a sample-collection date + time window before adding a
/// lab test to cart. Pops `(date, timeSlot)` on confirm, `null` if dismissed.
class ScheduleLabTestSheet extends StatefulWidget {
  const ScheduleLabTestSheet({super.key});

  @override
  State<ScheduleLabTestSheet> createState() => _ScheduleLabTestSheetState();
}

class _ScheduleLabTestSheetState extends State<ScheduleLabTestSheet> {
  static final _dateFormat = DateFormat('EEEE, d MMM yyyy');

  late DateTime _date = _today();
  String _slot = kLabTestTimeSlots.first;

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _pickDate() async {
    final today = _today();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: today,
      lastDate: today.add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          Text('Schedule sample collection', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppConstants.spacingLg),
          Text('Date', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppConstants.spacingXs),
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(_dateFormat.format(_date)),
              trailing: TextButton(onPressed: _pickDate, child: const Text('Change')),
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Text('Preferred time', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppConstants.spacingSm),
          Wrap(
            spacing: AppConstants.spacingSm,
            runSpacing: AppConstants.spacingSm,
            children: [
              for (final slot in kLabTestTimeSlots)
                ChoiceChip(
                  label: Text(slot),
                  selected: _slot == slot,
                  onSelected: (_) => setState(() => _slot = slot),
                ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingLg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop((_date, _slot)),
              child: const Text('Add to cart'),
            ),
          ),
        ],
      ),
    );
  }
}
