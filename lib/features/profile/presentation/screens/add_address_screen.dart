import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/profile/domain/address.dart';
import 'package:sunil_medical_store/features/profile/presentation/providers/address_controller.dart';

/// Form to add a new delivery address.
class AddAddressScreen extends ConsumerStatefulWidget {
  const AddAddressScreen({super.key});

  @override
  ConsumerState<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends ConsumerState<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _line1 = TextEditingController();
  final _line2 = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pincode = TextEditingController();

  AddressType _type = AddressType.home;
  bool _makeDefault = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _line1.dispose();
    _line2.dispose();
    _city.dispose();
    _state.dispose();
    _pincode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(addressesProvider.notifier).add(
        type: _type,
        line1: _line1.text.trim(),
        line2: _line2.text.trim().isEmpty ? null : _line2.text.trim(),
        city: _city.text.trim(),
        stateName: _state.text.trim(),
        pincode: _pincode.text.trim(),
        makeDefault: _makeDefault,
      );
      if (mounted) context.pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add address')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          children: [
            SegmentedButton<AddressType>(
              segments: const [
                ButtonSegment(value: AddressType.home, label: Text('Home'), icon: Icon(Icons.home_outlined)),
                ButtonSegment(value: AddressType.work, label: Text('Work'), icon: Icon(Icons.work_outline)),
                ButtonSegment(value: AddressType.other, label: Text('Other'), icon: Icon(Icons.location_on_outlined)),
              ],
              selected: {_type},
              onSelectionChanged: _saving ? null : (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: AppConstants.spacingLg),
            TextFormField(
              controller: _line1,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Address line 1'),
              validator: _required,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            TextFormField(
              controller: _line2,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Address line 2 (optional)'),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            TextFormField(
              controller: _city,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'City'),
              validator: _required,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            TextFormField(
              controller: _state,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'State'),
              validator: _required,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            TextFormField(
              controller: _pincode,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'PIN code'),
              validator: (v) => (v == null || v.trim().length != 6) ? 'Enter a 6-digit PIN code' : null,
            ),
            const SizedBox(height: AppConstants.spacingSm),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _makeDefault,
              onChanged: _saving ? null : (v) => setState(() => _makeDefault = v ?? false),
              title: const Text('Set as default address'),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppConstants.spacingSm),
              Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: AppConstants.spacingMd),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save address'),
            ),
          ],
        ),
      ),
    );
  }
}
