import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/admin/appointments/domain/doctor_admin_repository.dart';
import 'package:sunil_medical_store/features/admin/appointments/presentation/providers/doctor_admin_providers.dart';
import 'package:sunil_medical_store/features/admin/appointments/presentation/widgets/weekday_selector.dart';
import 'package:sunil_medical_store/features/appointments/domain/doctor.dart';

/// Admin > Doctors > Add / Edit. [doctorId] null = Add; populated = Edit.
class AddOrEditDoctorScreen extends ConsumerWidget {
  const AddOrEditDoctorScreen({super.key, this.doctorId});

  final String? doctorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (doctorId == null) {
      return const _DoctorForm(existing: null);
    }
    final async = ref.watch(adminDoctorByIdProvider(doctorId!));
    return async.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Edit doctor')),
        body: Center(
          child: Text(error is ApiException ? error.message : 'Could not load doctor.'),
        ),
      ),
      data: (doctor) => _DoctorForm(existing: doctor),
    );
  }
}

class _DoctorForm extends ConsumerStatefulWidget {
  const _DoctorForm({required this.existing});

  final Doctor? existing;

  bool get isEdit => existing != null;

  @override
  ConsumerState<_DoctorForm> createState() => _DoctorFormState();
}

class _DoctorFormState extends ConsumerState<_DoctorForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _specialization;
  late final TextEditingController _qualification;
  late final TextEditingController _experience;
  late final TextEditingController _fee;
  late final TextEditingController _hours;
  late final TextEditingController _photoUrl;

  late Set<int> _weekdays;
  bool _saving = false;
  bool _deleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final d = widget.existing;
    _name = TextEditingController(text: d?.name ?? '');
    _specialization = TextEditingController(text: d?.specialization ?? '');
    _qualification = TextEditingController(text: d?.qualification ?? '');
    _experience = TextEditingController(text: d?.experienceYears.toString() ?? '');
    _fee = TextEditingController(text: d?.consultationFee.toString() ?? '');
    _hours = TextEditingController(text: d?.availableTime ?? '');
    _photoUrl = TextEditingController(text: d?.photoUrl ?? '');
    _weekdays = {...?d?.availableWeekdays};
  }

  @override
  void dispose() {
    _name.dispose();
    _specialization.dispose();
    _qualification.dispose();
    _experience.dispose();
    _fee.dispose();
    _hours.dispose();
    _photoUrl.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;

  String? _requiredInt(String? value, {int min = 0}) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final parsed = int.tryParse(value.trim());
    if (parsed == null) return 'Enter a whole number';
    if (parsed < min) return 'Must be ≥ $min';
    return null;
  }

  DoctorInput _buildInput() => DoctorInput(
    name: _name.text.trim(),
    specialization: _specialization.text.trim(),
    qualification: _qualification.text.trim(),
    experienceYears: int.parse(_experience.text.trim()),
    consultationFee: int.parse(_fee.text.trim()),
    availableWeekdays: _weekdays.toList()..sort(),
    availableTime: _hours.text.trim(),
    photoUrl: _photoUrl.text.trim().isEmpty ? null : _photoUrl.text.trim(),
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_weekdays.isEmpty) {
      setState(() => _error = 'Pick at least one weekday');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(doctorAdminRepositoryProvider);
      if (widget.isEdit) {
        await repo.update(widget.existing!.id, _buildInput());
        ref.invalidate(adminDoctorByIdProvider(widget.existing!.id));
      } else {
        await repo.create(_buildInput());
      }
      ref.invalidate(adminDoctorsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(widget.isEdit ? 'Doctor updated' : 'Doctor added'),
          ));
        context.pop();
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (!widget.isEdit) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete doctor?'),
        content: Text(
          'This will remove ${widget.existing!.name} from the catalog. '
          'Existing appointments will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              foregroundColor: Theme.of(dialogCtx).colorScheme.onErrorContainer,
              backgroundColor: Theme.of(dialogCtx).colorScheme.errorContainer,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await ref.read(doctorAdminRepositoryProvider).delete(widget.existing!.id);
      ref.invalidate(adminDoctorsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Doctor deleted')));
        context.pop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _deleting = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final busy = _saving || _deleting;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit doctor' : 'Add doctor'),
        actions: [
          if (widget.isEdit)
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: busy ? null : _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          children: [
            TextFormField(
              controller: _name,
              enabled: !busy,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Dr. Ananya Sharma',
              ),
              validator: _required,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            TextFormField(
              controller: _specialization,
              enabled: !busy,
              decoration: const InputDecoration(labelText: 'Specialization'),
              validator: _required,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            TextFormField(
              controller: _qualification,
              enabled: !busy,
              decoration: const InputDecoration(
                labelText: 'Qualification',
                hintText: 'e.g. MBBS, MD (Internal Medicine)',
              ),
              validator: _required,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            TextFormField(
              controller: _experience,
              enabled: !busy,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Experience (yrs)'),
              validator: (v) => _requiredInt(v),
            ),
            if (widget.isEdit) ...[
              const SizedBox(height: AppConstants.spacingMd),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.star_rounded),
                  title: const Text('Rating'),
                  subtitle: const Text("Set by customers, not editable here"),
                  trailing: Text(
                    widget.existing!.ratingCount > 0
                        ? '${widget.existing!.rating.toStringAsFixed(1)} (${widget.existing!.ratingCount})'
                        : 'No ratings yet',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppConstants.spacingMd),
            TextFormField(
              controller: _fee,
              enabled: !busy,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Consultation fee (₹)'),
              validator: (v) => _requiredInt(v, min: 0),
            ),
            const Divider(height: AppConstants.spacingXl),
            Text('Availability', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              'Weekdays',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppConstants.spacingXs),
            WeekdaySelector(
              selected: _weekdays,
              onChanged: (next) => setState(() => _weekdays = next),
              enabled: !busy,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            TextFormField(
              controller: _hours,
              enabled: !busy,
              decoration: const InputDecoration(
                labelText: 'Consulting hours',
                hintText: 'e.g. 10:00 AM – 1:00 PM',
              ),
              validator: _required,
            ),
            const Divider(height: AppConstants.spacingXl),
            Text('Optional', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppConstants.spacingSm),
            TextFormField(
              controller: _photoUrl,
              enabled: !busy,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'Photo URL'),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppConstants.spacingMd),
              Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: AppConstants.spacingLg),
            FilledButton(
              onPressed: busy ? null : _save,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(widget.isEdit ? 'Save changes' : 'Add doctor'),
            ),
          ],
        ),
      ),
    );
  }
}
