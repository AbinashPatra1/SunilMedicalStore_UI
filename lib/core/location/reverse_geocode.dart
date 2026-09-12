import 'package:geocoding/geocoding.dart';
import 'package:sunil_medical_store/core/location/location_exception.dart';

/// A device-side reverse-geocoded address breakdown — derived entirely
/// on-device via the `geocoding` package, no Maps API billing (see backlog
/// #11's "device-only Geocoder + Haversine distance" decision).
class GeocodedAddress {
  const GeocodedAddress({
    required this.area,
    required this.city,
    required this.state,
    required this.pincode,
  });

  /// Locality/neighbourhood (the placemark's sub-locality, falling back to
  /// its locality if that's absent). `null` if neither is available.
  final String? area;
  final String city;
  final String state;
  final String pincode;
}

/// Reverse-geocodes [latitude]/[longitude] into a locality breakdown.
/// Throws [LocationException] if no placemark is found for the coordinates.
Future<GeocodedAddress> reverseGeocode(double latitude, double longitude) async {
  final placemarks = await placemarkFromCoordinates(latitude, longitude);
  if (placemarks.isEmpty) {
    throw const LocationException('Could not determine an address for this location.');
  }
  final placemark = placemarks.first;
  final subLocality = placemark.subLocality;
  final locality = placemark.locality;
  return GeocodedAddress(
    area: (subLocality != null && subLocality.isNotEmpty) ? subLocality : locality,
    city: locality ?? placemark.subAdministrativeArea ?? '',
    state: placemark.administrativeArea ?? '',
    pincode: placemark.postalCode ?? '',
  );
}
