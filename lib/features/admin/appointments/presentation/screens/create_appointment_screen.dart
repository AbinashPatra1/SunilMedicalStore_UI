import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/admin/appointments/presentation/providers/admin_appointment_providers.dart';
import 'package:sunil_medical_store/features/admin/appointments/presentation/providers/doctor_admin_providers.dart';
import 'package:sunil_medical_store/features/admin/appointments/presentation/widgets/pick_user_sheet.dart';
import 'package:sunil_medical_store/features/admin/users/domain/admin_user.dart';
import 'package:sunil_medical_store/features/appointments/domain/doctor.dart';

/// Admin creates a new appointment on a user's behalf: pick user → pick
/// doctor → pick date → submit. Time slot comes from the doctor's advertised
/// consulting hours (per product decision — one appointment per doctor per day).
class CreateAppointmentScreen extends ConsumerStatefulWidget {
  const CreateAppointmentScreen({super.key});

  @override
  ConsumerState<CreateAppointmentScreen> createState() =>
      _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState extends ConsumerState<CreateAppointmentScreen> {
  AdminUser? _user;
  Doctor? _doctor;
  DateTime? _date;
  bool _saving = false;
  String? _error;

  bool get _canSubmit => _user != null && _doctor != null && _date != null;

  Future<void> _pickUser() async {
    final chosen = await showModalBottomSheet<AdminUser>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const PickUserSheet(),
    );
    if (chosen != null) setState(() => _user = chosen);
  }

  Future<void> _pickDate() async {
    if (_doctor == null) return;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? todayDate,
      firstDate: todayDate,
      lastDate: todayDate.add(const Duration(days: 90)),
      selectableDayPredicate: (day) =>
          _doctor!.availableWeekdays.contains(day.weekday),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(adminAppointmentRepositoryProvider).createOnBehalf(
        userId: _user!.id,
        doctorId: _doctor!.id,
        date: _date!,
        timeSlot: _doctor!.availableTime,
      );
      ref.invalidate(adminAppointmentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text('Appointment booked for ${_user!.fullName}'),
          ));
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
    final doctorsAsync = ref.watch(adminDoctorsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New appointment')),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        children: [
          Text('For user', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppConstants.spacingSm),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  _user?.initials ?? '?',
                  style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                ),
              ),
              title: Text(_user?.fullName ?? 'Choose a user'),
              subtitle: _user == null ? null : Text(_user!.displayPhone),
              trailing: TextButton(
                onPressed: _saving ? null : _pickUser,
                child: Text(_user == null ? 'Pick' : 'Change'),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          Text('Doctor', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppConstants.spacingSm),
          doctorsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const Text('Could not load doctors'),
            data: (doctors) => Card(
              child: DropdownButtonFormField<String>(
                initialValue: _doctor?.id,
                decoration: const InputDecoration(
                  labelText: 'Choose doctor',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingMd,
                    vertical: AppConstants.spacingSm,
                  ),
                ),
                items: [
                  for (final d in doctors)
                    DropdownMenuItem(
                      value: d.id,
                      child: Text('${d.name} · ${d.specialization}'),
                    ),
                ],
                onChanged: _saving
                    ? null
                    : (id) {
                        setState(() {
                          _doctor = doctors.firstWhere((d) => d.id == id);
                          // Reset date if it no longer fits the new doctor's schedule.
                          if (_date != null &&
                              !_doctor!.availableWeekdays.contains(_date!.weekday)) {
                            _date = null;
                          }
                        });
                      },
              ),
            ),
          ),
          if (_doctor != null) ...[
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              'Consulting hours: ${_doctor!.availableTime}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: AppConstants.spacingLg),
          Text('Date', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppConstants.spacingSm),
          Card(
            child: ListTile(
              leading: const Icon(Icons.event),
              title: Text(
                _date == null
                    ? 'Pick a date'
                    : DateFormat('EEE, d MMM yyyy').format(_date!),
              ),
              subtitle: _doctor == null
                  ? const Text('Choose a doctor first')
                  : null,
              trailing: TextButton(
                onPressed: (_doctor == null || _saving) ? null : _pickDate,
                child: Text(_date == null ? 'Pick' : 'Change'),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppConstants.spacingMd),
            Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: AppConstants.spacingLg),
          FilledButton(
            onPressed: (!_canSubmit || _saving) ? null : _submit,
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Book appointment'),
          ),
        ],
      ),
    );
  }
}
