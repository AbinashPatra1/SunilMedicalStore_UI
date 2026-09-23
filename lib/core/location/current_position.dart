import 'package:geolocator/geolocator.dart';
import 'package:sunil_medical_store/core/location/location_exception.dart';

/// Requests location permission if needed and returns the device's current
/// GPS fix. Throws [LocationException] with a user-facing message on any
/// failure (services disabled, permission denied/permanently denied) —
/// shared by the customer "Use current location" (Add Address) and the
/// admin "Set as store location" (Delivery Settings) flows.
Future<Position> getCurrentPosition() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw const LocationException('Turn on location services to use this.');
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied) {
    throw const LocationException('Location permission denied.');
  }
  if (permission == LocationPermission.deniedForever) {
    throw const LocationException(
      'Location permission permanently denied — enable it from system settings.',
    );
  }

  return Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
  );
}

/// Asks for location permission up front (called right after sign-in) so the
/// system prompt shows once, early, rather than the first time a location
/// feature is used. Never throws and never asks again after a refusal —
/// features that need a fix still go through [getCurrentPosition], which
/// explains what to do.
Future<void> requestLocationPermissionIfNeeded() async {
  try {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  } catch (_) {
    // No location plugin (tests) or a platform hiccup — nothing to do.
  }
}
