/// The store's reference point + delivery radius, used to gate pharmacy-only
/// checkout (see backlog #11). Lab tests and appointments are never gated.
class DeliverySettings {
  const DeliverySettings({
    required this.storeLatitude,
    required this.storeLongitude,
    required this.radiusKm,
  });

  final double storeLatitude;
  final double storeLongitude;
  final double radiusKm;
}
