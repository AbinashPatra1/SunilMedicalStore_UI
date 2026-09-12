/// The kind of address, used for the label and icon.
enum AddressType {
  home,
  work,
  other;

  String get label => switch (this) {
    AddressType.home => 'Home',
    AddressType.work => 'Work',
    AddressType.other => 'Other',
  };
}

/// A saved delivery address.
class Address {
  const Address({
    required this.id,
    required this.type,
    required this.line1,
    this.line2,
    required this.city,
    required this.state,
    required this.pincode,
    this.area,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  final String id;
  final AddressType type;
  final String line1;
  final String? line2;
  final String city;
  final String state;
  final String pincode;

  /// Locality/neighbourhood, derived via on-device reverse-geocoding when
  /// this address was added using "Use current location". `null` for
  /// manually-entered addresses, or ones added before this existed.
  final String? area;

  /// Device-captured coordinates, present only when added via "Use current
  /// location" — `null` for manually-entered addresses (no backfill for
  /// ones added before this existed either). The delivery-radius check
  /// treats a `null` value as "can't verify, allow the order" rather than
  /// blocking it.
  final double? latitude;
  final double? longitude;

  final bool isDefault;

  /// Single-line formatted address for display.
  String get formatted => [
    line1,
    if (line2 != null && line2!.isNotEmpty) line2,
    '$city, $state $pincode',
  ].join(', ');

  Address copyWith({bool? isDefault}) {
    return Address(
      id: id,
      type: type,
      line1: line1,
      line2: line2,
      city: city,
      state: state,
      pincode: pincode,
      area: area,
      latitude: latitude,
      longitude: longitude,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
