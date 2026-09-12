import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_client.dart';
import 'package:sunil_medical_store/features/profile/data/api_address_repository.dart';
import 'package:sunil_medical_store/features/profile/domain/address.dart';
import 'package:sunil_medical_store/features/profile/domain/address_repository.dart';

final addressRepositoryProvider = Provider<AddressRepository>((ref) {
  return ApiAddressRepository(ref.watch(dioProvider));
});

/// The customer's saved addresses. Mutation methods (`add`/`setDefault`/
/// `remove`) call the API then refresh [state] — errors from the mutation
/// call itself propagate to the caller (so a screen can show "why did this
/// fail"), while a refresh failure surfaces as the usual `AsyncError` state.
final addressesProvider = AsyncNotifierProvider<AddressController, List<Address>>(
  AddressController.new,
);

class AddressController extends AsyncNotifier<List<Address>> {
  AddressRepository get _repository => ref.read(addressRepositoryProvider);

  @override
  Future<List<Address>> build() => _repository.list();

  Future<void> add({
    required AddressType type,
    required String line1,
    String? line2,
    required String city,
    required String stateName,
    required String pincode,
    String? area,
    double? latitude,
    double? longitude,
    bool makeDefault = false,
  }) async {
    await _repository.add(
      type: type,
      line1: line1,
      line2: line2,
      city: city,
      state: stateName,
      pincode: pincode,
      area: area,
      latitude: latitude,
      longitude: longitude,
      makeDefault: makeDefault,
    );
    state = await AsyncValue.guard(() => _repository.list());
  }

  Future<void> setDefault(String id) async {
    await _repository.setDefault(id);
    state = await AsyncValue.guard(() => _repository.list());
  }

  Future<void> remove(String id) async {
    await _repository.remove(id);
    state = await AsyncValue.guard(() => _repository.list());
  }
}
