import 'package:sunil_medical_store/features/profile/domain/address.dart';

/// Reads and mutates the caller's saved addresses, implemented by the data
/// layer.
abstract interface class AddressRepository {
  Future<List<Address>> list();

  Future<Address> add({
    required AddressType type,
    required String line1,
    String? line2,
    required String city,
    required String state,
    required String pincode,
    String? area,
    double? latitude,
    double? longitude,
    bool makeDefault = false,
  });

  Future<void> setDefault(String id);
  Future<void> remove(String id);
}
