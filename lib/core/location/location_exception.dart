/// Thrown when the device's location can't be captured — permission denied,
/// location services disabled, or the underlying platform call failed.
class LocationException implements Exception {
  const LocationException(this.message);

  final String message;
}
