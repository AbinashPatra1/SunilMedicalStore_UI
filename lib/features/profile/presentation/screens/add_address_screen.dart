import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

  @override
  void dispose() {
    _line1.dispose();
    _line2.dispose();
    _city.dispose();
    _state.dispose();
    _pincode.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(addressesProvider.notifier).add(
      type: _type,
      line1: _line1.text.trim(),
      line2: _line2.text.trim().isEmpty ? null : _line2.text.trim(),
      city: _city.text.trim(),
      stateName: _state.text.trim(),
      pincode: _pincode.text.trim(),
      makeDefault: _makeDefault,
    );
    context.pop();
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
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
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: AppConstants.spacingLg),
            TextFormField(
              controller: _line1,
              decoration: const InputDecoration(labelText: 'Address line 1'),
              validator: _required,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            TextFormField(
              controller: _line2,
              decoration: const InputDecoration(labelText: 'Address line 2 (optional)'),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            TextFormField(
              controller: _city,
              decoration: const InputDecoration(labelText: 'City'),
              validator: _required,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            TextFormField(
              controller: _state,
              decoration: const InputDecoration(labelText: 'State'),
              validator: _required,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            TextFormField(
              controller: _pincode,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'PIN code'),
              validator: (v) => (v == null || v.trim().length != 6) ? 'Enter a 6-digit PIN code' : null,
            ),
            const SizedBox(height: AppConstants.spacingSm),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _makeDefault,
              onChanged: (v) => setState(() => _makeDefault = v ?? false),
              title: const Text('Set as default address'),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            FilledButton(onPressed: _save, child: const Text('Save address')),
          ],
        ),
      ),
    );
  }
}
