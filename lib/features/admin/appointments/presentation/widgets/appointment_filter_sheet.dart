import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/admin/appointments/domain/admin_appointment_repository.dart';
import 'package:sunil_medical_store/features/admin/appointments/presentation/providers/doctor_admin_providers.dart';
import 'package:sunil_medical_store/features/admin/appointments/presentation/widgets/weekday_selector.dart';
import 'package:sunil_medical_store/features/appointments/domain/doctor.dart';
import 'package:sunil_medical_store/features/profile/domain/past_appointment.dart';

/// Modal bottom sheet for editing [AppointmentFilters]. Emits the new value
/// via [onApply] when the user hits Apply; Clear resets to defaults.
class AppointmentFilterSheet extends ConsumerStatefulWidget {
  const AppointmentFilterSheet({
    super.key,
    required this.initial,
    required this.onApply,
  });

  final AppointmentFilters initial;
  final ValueChanged<AppointmentFilters> onApply;

  @override
  ConsumerState<AppointmentFilterSheet> createState() => _AppointmentFilterSheetState();
}

class _AppointmentFilterSheetState extends ConsumerState<AppointmentFilterSheet> {
  AppointmentStatus? _status;
  String? _doctorId;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  int? _weekday;

  @override
  void initState() {
    super.initState();
    _status = widget.initial.status;
    _doctorId = widget.initial.doctorId;
    _dateFrom = widget.initial.dateFrom;
    _dateTo = widget.initial.dateTo;
    _weekday = widget.initial.weekday;
  }

  Future<void> _pickDate(bool from) async {
    final now = DateTime.now();
    final initial = (from ? _dateFrom : _dateTo) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    setState(() {
      if (from) {
        _dateFrom = picked;
        if (_dateTo != null && _dateTo!.isBefore(picked)) _dateTo = picked;
      } else {
        _dateTo = picked;
        if (_dateFrom != null && _dateFrom!.isAfter(picked)) _dateFrom = picked;
      }
    });
  }

  void _apply() {
    // Preserve search from the caller — it's owned by the app bar, not this
    // sheet.
    widget.onApply(AppointmentFilters(
      search: widget.initial.search,
      status: _status,
      doctorId: _doctorId,
      dateFrom: _dateFrom,
      dateTo: _dateTo,
      weekday: _weekday,
    ));
    Navigator.of(context).pop();
  }

  void _clear() {
    widget.onApply(AppointmentFilters(search: widget.initial.search));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final doctorsAsync = ref.watch(adminDoctorsProvider);
    final formatter = DateFormat('d MMM yyyy');

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppConstants.spacingLg,
          right: AppConstants.spacingLg,
          top: AppConstants.spacingLg,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppConstants.spacingLg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Filters', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  TextButton(onPressed: _clear, child: const Text('Clear')),
                ],
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Text('Status', style: theme.textTheme.titleSmall),
              const SizedBox(height: AppConstants.spacingXs),
              Wrap(
                spacing: AppConstants.spacingSm,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _status == null,
                    onSelected: (_) => setState(() => _status = null),
                  ),
                  for (final s in AppointmentStatus.values)
                    ChoiceChip(
                      label: Text(s.label),
                      selected: _status == s,
                      onSelected: (_) => setState(() => _status = s),
                    ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingLg),
              Text('Doctor', style: theme.textTheme.titleSmall),
              const SizedBox(height: AppConstants.spacingXs),
              doctorsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('Could not load doctors'),
                data: (doctors) => DropdownButtonFormField<String?>(
                  initialValue: _doctorId,
                  decoration: const InputDecoration(labelText: 'Any doctor'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Any doctor')),
                    for (final Doctor d in doctors)
                      DropdownMenuItem<String?>(value: d.id, child: Text(d.name)),
                  ],
                  onChanged: (v) => setState(() => _doctorId = v),
                ),
              ),
              const SizedBox(height: AppConstants.spacingLg),
              Text('Date range', style: theme.textTheme.titleSmall),
              const SizedBox(height: AppConstants.spacingXs),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(true),
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(_dateFrom == null ? 'From' : formatter.format(_dateFrom!)),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingSm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(false),
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(_dateTo == null ? 'To' : formatter.format(_dateTo!)),
                    ),
                  ),
                ],
              ),
              if (_dateFrom != null || _dateTo != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(() {
                      _dateFrom = null;
                      _dateTo = null;
                    }),
                    child: const Text('Clear dates'),
                  ),
                ),
              const SizedBox(height: AppConstants.spacingLg),
              Text('Day of week', style: theme.textTheme.titleSmall),
              const SizedBox(height: AppConstants.spacingXs),
              WeekdaySelector(
                selected: _weekday == null ? const {} : {_weekday!},
                onChanged: (next) => setState(() {
                  // Single-select semantics for filtering.
                  _weekday = next.isEmpty ? null : next.last;
                }),
              ),
              const SizedBox(height: AppConstants.spacingXl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _apply,
                  child: const Text('Apply filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
