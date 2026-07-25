import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/features/profile/domain/address.dart';

/// Holds the customer's saved addresses in memory (seeded with dummy data).
///
/// Replace the seed and wire [add]/[setDefault]/[remove] to a backend when the
/// API lands — the UI reading `addressesProvider` won't change.
final addressesProvider = NotifierProvider<AddressController, List<Address>>(
  AddressController.new,
);

class AddressController extends Notifier<List<Address>> {
  var _seq = 0;

  @override
  List<Address> build() => const [
    Address(id: 'addr-0', type: AddressType.home, line1: '12, Green Park Colony', line2: 'Near City Hospital', city: 'Bhubaneswar', state: 'Odisha', pincode: '751001', isDefault: true),
    Address(id: 'addr-1', type: AddressType.work, line1: 'Tower B, Tech Park', city: 'Bhubaneswar', state: 'Odisha', pincode: '751024'),
  ];

  /// Adds a new address. It becomes the default if requested or if it's the
  /// first address saved.
  void add({
    required AddressType type,
    required String line1,
    String? line2,
    required String city,
    required String stateName,
    required String pincode,
    bool makeDefault = false,
  }) {
    final becomesDefault = makeDefault || state.isEmpty;
    final address = Address(
      id: 'addr-new-${_seq++}',
      type: type,
      line1: line1,
      line2: line2,
      city: city,
      state: stateName,
      pincode: pincode,
      isDefault: becomesDefault,
    );
    final base = becomesDefault
        ? state.map((a) => a.copyWith(isDefault: false)).toList()
        : List<Address>.from(state);
    state = [...base, address];
  }

  void setDefault(String id) {
    state = [for (final a in state) a.copyWith(isDefault: a.id == id)];
  }

  void remove(String id) {
    state = state.where((a) => a.id != id).toList();
  }
}
