import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/location/current_position.dart';
import 'package:sunil_medical_store/core/location/location_exception.dart';
import 'package:sunil_medical_store/core/location/reverse_geocode.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/admin/delivery/domain/delivery_settings.dart';
import 'package:sunil_medical_store/features/admin/delivery/presentation/providers/delivery_settings_providers.dart';

/// Admin > More > Delivery Settings: capture the store's own location (via
/// device GPS — no Maps API billing, see backlog #11) and set the delivery
/// radius that gates pharmacy-only checkout for customers outside it.
class AdminDeliverySettingsScreen extends ConsumerStatefulWidget {
  const AdminDeliverySettingsScreen({super.key});

  @override
  ConsumerState<AdminDeliverySettingsScreen> createState() => _AdminDeliverySettingsScreenState();
}

class _AdminDeliverySettingsScreenState extends ConsumerState<AdminDeliverySettingsScreen> {
  final _radiusController = TextEditingController();

  double? _latitude;
  double? _longitude;
  String? _locationPreview;
  bool _locating = false;
  bool _saving = false;
  String? _error;
  bool _seeded = false;

  @override
  void dispose() {
    _radiusController.dispose();
    super.dispose();
  }

  void _seedFrom(DeliverySettings? settings) {
    if (_seeded || settings == null) return;
    _seeded = true;
    _latitude = settings.storeLatitude;
    _longitude = settings.storeLongitude;
    _radiusController.text = settings.radiusKm.toString();
  }

  Future<void> _captureStoreLocation() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      final position = await getCurrentPosition();
      String? preview;
      try {
        final geocoded = await reverseGeocode(position.latitude, position.longitude);
        preview = [
          geocoded.area,
          geocoded.city,
          geocoded.state,
        ].where((s) => s != null && s.isNotEmpty).join(', ');
      } catch (_) {
        // Nice-to-have confirmation text only — the coordinates below are
        // what actually gets saved, so a failed reverse-geocode isn't fatal.
      }
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationPreview = (preview != null && preview.isNotEmpty) ? preview : null;
      });
    } on LocationException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    if (_latitude == null || _longitude == null) {
      setState(() => _error = 'Set the store location first.');
      return;
    }
    final radius = double.tryParse(_radiusController.text.trim());
    if (radius == null || radius <= 0) {
      setState(() => _error = 'Enter a valid delivery radius in km.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(deliverySettingsRepositoryProvider)
          .update(storeLatitude: _latitude!, storeLongitude: _longitude!, radiusKm: radius);
      ref.invalidate(deliverySettingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Delivery settings saved')));
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
    final async = ref.watch(deliverySettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Settings')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(error is ApiException ? error.message : 'Could not load delivery settings.'),
        ),
        data: (settings) {
          _seedFrom(settings);
          return ListView(
            padding: const EdgeInsets.all(AppConstants.spacingLg),
            children: [
              Text(
                'Pharmacy orders are blocked outside this radius from the store. '
                'Lab tests and appointments are never affected.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppConstants.spacingLg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Store location', style: theme.textTheme.titleMedium),
                      const SizedBox(height: AppConstants.spacingSm),
                      if (_latitude != null && _longitude != null)
                        Text(
                          _locationPreview ??
                              '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                          style: theme.textTheme.bodyMedium,
                        )
                      else
                        Text(
                          'Not set yet',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      const SizedBox(height: AppConstants.spacingSm),
                      OutlinedButton.icon(
                        onPressed: (_locating || _saving) ? null : _captureStoreLocation,
                        icon: _locating
                            ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.my_location),
                        label: Text(_latitude == null ? 'Set as store location' : 'Update store location'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingLg),
              TextField(
                controller: _radiusController,
                enabled: !_saving,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Delivery radius (km)'),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppConstants.spacingSm),
                Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: AppConstants.spacingLg),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
