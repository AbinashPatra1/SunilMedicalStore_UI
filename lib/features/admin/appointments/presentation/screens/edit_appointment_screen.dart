import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/admin/appointments/domain/admin_appointment.dart';
import 'package:sunil_medical_store/features/admin/appointments/presentation/providers/admin_appointment_providers.dart';
import 'package:sunil_medical_store/features/admin/presentation/widgets/status_swipe_bar.dart';
import 'package:sunil_medical_store/features/profile/domain/past_appointment.dart';
import 'package:sunil_medical_store/features/profile/presentation/widgets/status_chip.dart';

/// Admin edits an existing appointment: reschedule the date (applies
/// immediately once picked), advance status one linear step at a time
/// (`upcoming → inSession → completed`, swipe-confirmed), or cancel via a
/// separate always-available action. Doctor and user stay the same (per
/// product decision).
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
  late AdminAppointment _appointment = widget.existing;
  bool _busy = false;
  String? _error;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _appointment.dateTime,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    // Preserve time-of-day from the current appointment — only the date
    // itself is being moved, not the doctor's slot time.
    final newDate = DateTime(
      picked.year,
      picked.month,
      picked.day,
      _appointment.dateTime.hour,
      _appointment.dateTime.minute,
    );
    await _apply(newDate: newDate, successMessage: 'Appointment rescheduled');
  }

  Future<void> _advance() async {
    final next = _appointment.status.next;
    if (next == null) return;
    await _apply(status: next, successMessage: 'Appointment marked ${next.label}');
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel appointment?'),
        content: Text(
          "This will cancel ${_appointment.userName}'s appointment with "
          '${_appointment.doctorName}. This can\'t be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep appointment'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.onErrorContainer,
              backgroundColor: Theme.of(dialogContext).colorScheme.errorContainer,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel appointment'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _apply(status: AppointmentStatus.cancelled, successMessage: 'Appointment cancelled');
  }

  Future<void> _apply({
    AppointmentStatus? status,
    DateTime? newDate,
    required String successMessage,
  }) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final updated = await ref
          .read(adminAppointmentRepositoryProvider)
          .update(_appointment.id, status: status, newDate: newDate);
      ref.invalidate(adminAppointmentsProvider);
      if (mounted) {
        setState(() => _appointment = updated);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = _appointment;
    final formattedDate = DateFormat('EEE, d MMM yyyy').format(a.dateTime);
    final formattedTime = DateFormat('h:mm a').format(a.dateTime);
    final advanceLabel = a.status.advanceLabel;

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
                  if (a.appointmentNumber != null)
                    Text(
                      a.appointmentNumber!,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
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
          Text('Date', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppConstants.spacingSm),
          Card(
            child: ListTile(
              leading: const Icon(Icons.event_outlined),
              title: Text(formattedDate),
              subtitle: Text('Time: $formattedTime (from doctor\'s schedule)'),
              trailing: TextButton(
                onPressed: _busy ? null : _pickDate,
                child: const Text('Change'),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          Row(
            children: [
              Text('Status', style: theme.textTheme.titleMedium),
              const SizedBox(width: AppConstants.spacingSm),
              StatusChip(label: a.status.label, positive: a.status != AppointmentStatus.cancelled),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm),
          if (advanceLabel != null)
            StatusSwipeBar(
              label: advanceLabel,
              enabled: !_busy,
              onConfirm: _advance,
            ),
          if (_error != null) ...[
            const SizedBox(height: AppConstants.spacingMd),
            Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: AppConstants.spacingLg),
          OutlinedButton.icon(
            onPressed: (_busy || a.status == AppointmentStatus.cancelled) ? null : _cancel,
            style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancel appointment'),
          ),
        ],
      ),
    );
  }
}
