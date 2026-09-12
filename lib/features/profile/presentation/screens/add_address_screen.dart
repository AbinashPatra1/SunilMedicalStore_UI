import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/location/current_position.dart';
import 'package:sunil_medical_store/core/location/location_exception.dart';
import 'package:sunil_medical_store/core/location/reverse_geocode.dart';
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
  final _area = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pincode = TextEditingController();

  AddressType _type = AddressType.home;
  bool _makeDefault = false;
  bool _saving = false;
  String? _error;

  // Set once "Use current location" succeeds; cleared by "Edit manually".
  // The captured coordinates themselves persist through a later manual
  // edit — only the city/state/pincode/area fields flip back to editable.
  bool _locationCaptured = false;
  bool _locating = false;
  String? _locationError;
  double? _latitude;
  double? _longitude;

  @override
  void dispose() {
    _line1.dispose();
    _line2.dispose();
    _area.dispose();
    _city.dispose();
    _state.dispose();
    _pincode.dispose();
    super.dispose();
  }

  Future<void> _captureLocation() async {
    setState(() {
      _locating = true;
      _locationError = null;
    });
    try {
      final position = await getCurrentPosition();
      final geocoded = await reverseGeocode(position.latitude, position.longitude);
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _area.text = geocoded.area ?? '';
        _city.text = geocoded.city;
        _state.text = geocoded.state;
        _pincode.text = geocoded.pincode;
        _locationCaptured = true;
      });
    } on LocationException catch (e) {
      if (mounted) setState(() => _locationError = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _locationError = 'Could not determine your address from this location.');
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
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
        area: _area.text.trim().isEmpty ? null : _area.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
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
            OutlinedButton.icon(
              onPressed: (_saving || _locating) ? null : _captureLocation,
              icon: _locating
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location),
              label: Text(_locationCaptured ? 'Update current location' : 'Use current location'),
            ),
            if (_locationError != null) ...[
              const SizedBox(height: AppConstants.spacingSm),
              Text(_locationError!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
            ],
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
              controller: _area,
              enabled: !_saving,
              readOnly: _locationCaptured,
              decoration: InputDecoration(
                labelText: 'Area / locality (optional)',
                helperText: _locationCaptured ? 'From your current location' : null,
              ),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            TextFormField(
              controller: _city,
              enabled: !_saving,
              readOnly: _locationCaptured,
              decoration: InputDecoration(
                labelText: 'City',
                helperText: _locationCaptured ? 'From your current location' : null,
              ),
              validator: _required,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            TextFormField(
              controller: _state,
              enabled: !_saving,
              readOnly: _locationCaptured,
              decoration: InputDecoration(
                labelText: 'State',
                helperText: _locationCaptured ? 'From your current location' : null,
              ),
              validator: _required,
            ),
            const SizedBox(height: AppConstants.spacingMd),
            TextFormField(
              controller: _pincode,
              enabled: !_saving,
              readOnly: _locationCaptured,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'PIN code',
                helperText: _locationCaptured ? 'From your current location' : null,
              ),
              validator: (v) => (v == null || v.trim().length != 6) ? 'Enter a 6-digit PIN code' : null,
            ),
            if (_locationCaptured) ...[
              const SizedBox(height: AppConstants.spacingXs),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _saving ? null : () => setState(() => _locationCaptured = false),
                  child: const Text('Edit manually'),
                ),
              ),
            ],
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
