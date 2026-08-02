import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/admin/appointments/domain/admin_appointment.dart';
import 'package:sunil_medical_store/features/admin/appointments/presentation/providers/admin_appointment_providers.dart';
import 'package:sunil_medical_store/features/profile/domain/past_appointment.dart';

/// Admin edits an existing appointment: change status and/or reschedule the
/// date. Doctor and user stay the same (per product decision).
class EditAppointmentScreen extends ConsumerWidget {
  const EditAppointmentScreen({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminAppointmentByIdProvider(appointmentId));
    return async.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Appointment')),
        body: Center(
          child: Text(error is ApiException ? error.message : 'Could not load appointment.'),
        ),
      ),
      data: (appointment) => _EditForm(existing: appointment),
    );
  }
}

class _EditForm extends ConsumerStatefulWidget {
  const _EditForm({required this.existing});

  final AdminAppointment existing;

  @override
  ConsumerState<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends ConsumerState<_EditForm> {
  late AppointmentStatus _status;
  late DateTime _date;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _status = widget.existing.status;
    _date = widget.existing.dateTime;
  }

  bool get _statusChanged => _status != widget.existing.status;
  bool get _dateChanged => !_sameDate(_date, widget.existing.dateTime);

  static bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        // Preserve time-of-day from original.
        _date = DateTime(picked.year, picked.month, picked.day,
            _date.hour, _date.minute);
      });
    }
  }

  Future<void> _save() async {
    if (!_statusChanged && !_dateChanged) {
      context.pop();
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(adminAppointmentRepositoryProvider).update(
        widget.existing.id,
        status: _statusChanged ? _status : null,
        newDate: _dateChanged ? _date : null,
      );
      ref.invalidate(adminAppointmentByIdProvider(widget.existing.id));
      ref.invalidate(adminAppointmentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Appointment updated')));
        context.pop();
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = widget.existing;
    final formattedDate = DateFormat('EEE, d MMM yyyy').format(_date);
    final formattedTime = DateFormat('h:mm a').format(_date);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit appointment')),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        children: [
          // Read-only header showing who + which doctor.
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.userName, style: theme.textTheme.titleSmall),
                  Text(
                    a.userPhone,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppConstants.spacingSm),
                  Text(
                    '${a.doctorName} · ${a.specialization}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
                  ),
                  Text('₹${a.fee}', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          Text('Status', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppConstants.spacingSm),
          Wrap(
            spacing: AppConstants.spacingSm,
            children: [
              for (final s in AppointmentStatus.values)
                ChoiceChip(
                  label: Text(s.label),
                  selected: _status == s,
                  onSelected: _saving ? null : (_) => setState(() => _status = s),
                ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingLg),
          Text('Date', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppConstants.spacingSm),
          Card(
            child: ListTile(
              leading: const Icon(Icons.event),
              title: Text(formattedDate),
              subtitle: Text('Time: $formattedTime (from doctor\'s schedule)'),
              trailing: TextButton(
                onPressed: _saving ? null : _pickDate,
                child: const Text('Change'),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppConstants.spacingMd),
            Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: AppConstants.spacingLg),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save changes'),
          ),
        ],
      ),
    );
  }
}
