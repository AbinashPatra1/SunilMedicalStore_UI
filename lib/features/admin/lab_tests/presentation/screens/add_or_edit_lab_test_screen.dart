import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/admin/lab_tests/domain/lab_test_admin_repository.dart';
import 'package:sunil_medical_store/features/admin/lab_tests/presentation/providers/lab_test_admin_providers.dart';
import 'package:sunil_medical_store/features/lab_tests/domain/lab_test.dart';

/// Admin > Lab Tests > Add / Edit: single form for creating or editing a
/// lab test. Add mode when [testId] is null; edit mode fetches the
/// existing test to pre-fill.
class AddOrEditLabTestScreen extends ConsumerWidget {
  const AddOrEditLabTestScreen({super.key, this.testId});

  final String? testId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (testId == null) {
      return const _LabTestForm(existing: null);
    }
    final async = ref.watch(adminLabTestByIdProvider(testId!));
    return async.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Edit lab test')),
        body: Center(
          child: Text(error is ApiException ? error.message : 'Could not load lab test.'),
        ),
      ),
      data: (test) => _LabTestForm(existing: test),
    );
  }
}

class _LabTestForm extends ConsumerStatefulWidget {
  const _LabTestForm({required this.existing});

  final LabTest? existing;

  bool get isEdit => existing != null;

  @override
  ConsumerState<_LabTestForm> createState() => _LabTestFormState();
}

class _LabTestFormState extends ConsumerState<_LabTestForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _labName;
  late final TextEditingController _description;
  late final TextEditingController _sampleType;
  late final TextEditingController _reportTime;
  late final TextEditingController _price;
  late final TextEditingController _mrp;
  late final TextEditingController _parameters;
  late final TextEditingController _tags;

  bool _fastingRequired = false;
  bool _saving = false;
  bool _deleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _name = TextEditingController(text: t?.name ?? '');
    _labName = TextEditingController(text: t?.labName ?? '');
    _description = TextEditingController(text: t?.description ?? '');
    _sampleType = TextEditingController(text: t?.sampleType ?? '');
    _reportTime = TextEditingController(text: t?.reportTime ?? '');
    _price = TextEditingController(text: t?.price.toString() ?? '');
    _mrp = TextEditingController(text: t?.mrp?.toString() ?? '');
    _parameters = TextEditingController(text: t?.parameters.join(', ') ?? '');
    _tags = TextEditingController(text: t?.tags.join(', ') ?? '');
    _fastingRequired = t?.fastingRequired ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _labName.dispose();
    _description.dispose();
    _sampleType.dispose();
    _reportTime.dispose();
    _price.dispose();
    _mrp.dispose();
    _parameters.dispose();
    _tags.dispose();
    super.dispose();
  }

  String? _required(String? value) => (value == null || value.trim().isEmpty) ? 'Required' : null;

  String? _requiredInt(String? value, {int min = 0}) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final parsed = int.tryParse(value.trim());
    if (parsed == null) return 'Enter a whole number';
    if (parsed < min) return 'Must be ≥ $min';
    return null;
  }

  String? _optionalInt(String? value, {int min = 0}) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = int.tryParse(value.trim());
    if (parsed == null) return 'Enter a whole number';
    if (parsed < min) return 'Must be ≥ $min';
    return null;
  }

  List<String> _splitCsv(String text) =>
      text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  LabTestInput _buildInput() => LabTestInput(
    name: _name.text.trim(),
    labName: _labName.text.trim(),
    description: _description.text.trim(),
    sampleType: _sampleType.text.trim(),
    reportTime: _reportTime.text.trim(),
    fastingRequired: _fastingRequired,
    price: int.parse(_price.text.trim()),
    mrp: _mrp.text.trim().isEmpty ? null : int.parse(_mrp.text.trim()),
    parameters: _splitCsv(_parameters.text),
    tags: _splitCsv(_tags.text),
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_splitCsv(_parameters.text).isEmpty) {
      setState(() => _error = 'Add at least one parameter');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(labTestAdminRepositoryProvider);
      final input = _buildInput();
      if (widget.isEdit) {
        await repo.update(widget.existing!.id, input);
        ref.invalidate(adminLabTestByIdProvider(widget.existing!.id));
      } else {
        await repo.create(input);
      }
      ref.invalidate(adminLabTestsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(widget.isEdit ? 'Lab test updated' : 'Lab test added')),
          );
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
        title: const Text('Delete lab test?'),
        content: Text(
          'This will permanently remove "${widget.existing!.name}" from the catalog.',
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
      await ref.read(labTestAdminRepositoryProvider).delete(widget.existing!.id);
      ref.invalidate(adminLabTestsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Lab test deleted')));
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
        title: Text(widget.isEdit ? 'Edit lab test' : 'Add lab test'),
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
                hintText: 'e.g. Complete Blood Count (CBC)',
              ),
              validator: _required,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            TextFormField(
              controller: _labName,
              enabled: !busy,
              decoration: const InputDecoration(labelText: 'Lab name'),
              validator: _required,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            TextFormField(
              controller: _description,
              enabled: !busy,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'What this test screens for',
              ),
              validator: _required,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    enabled: !busy,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Price (₹)'),
                    validator: (v) => _requiredInt(v, min: 1),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingMd),
                Expanded(
                  child: TextFormField(
                    controller: _mrp,
                    enabled: !busy,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'MRP (₹, optional)'),
                    validator: (v) => _optionalInt(v, min: 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingMd),
            TextFormField(
              controller: _sampleType,
              enabled: !busy,
              decoration: const InputDecoration(
                labelText: 'Sample type',
                hintText: 'e.g. Blood, Urine, Blood & Urine',
              ),
              validator: _required,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            TextFormField(
              controller: _reportTime,
              enabled: !busy,
              decoration: const InputDecoration(
                labelText: 'Report time',
                hintText: 'e.g. Within 24 hours',
              ),
              validator: _required,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fasting required'),
              value: _fastingRequired,
              onChanged: busy ? null : (v) => setState(() => _fastingRequired = v),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            TextFormField(
              controller: _parameters,
              enabled: !busy,
              decoration: const InputDecoration(
                labelText: 'Parameters',
                hintText: 'Comma-separated, e.g. Hemoglobin, WBC count',
              ),
            ),
            const Divider(height: AppConstants.spacingXl),
            Text('Optional', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppConstants.spacingSm),
            TextFormField(
              controller: _tags,
              enabled: !busy,
              decoration: const InputDecoration(
                labelText: 'Tags',
                hintText: 'Comma-separated, e.g. diabetes, sugar',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppConstants.spacingMd),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: AppConstants.spacingLg),
            FilledButton(
              onPressed: busy ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.isEdit ? 'Save changes' : 'Add lab test'),
            ),
          ],
        ),
      ),
    );
  }
}
