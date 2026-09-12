import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_client.dart';
import 'package:sunil_medical_store/core/utils/distance.dart';
import 'package:sunil_medical_store/features/admin/delivery/presentation/providers/delivery_settings_providers.dart';
import 'package:sunil_medical_store/features/cart/data/api_order_repository.dart';
import 'package:sunil_medical_store/features/cart/data/api_promo_repository.dart';
import 'package:sunil_medical_store/features/cart/domain/cart_item.dart';
import 'package:sunil_medical_store/features/cart/domain/order_repository.dart';
import 'package:sunil_medical_store/features/cart/domain/promo_code.dart';
import 'package:sunil_medical_store/features/cart/domain/promo_repository.dart';
import 'package:sunil_medical_store/features/lab_tests/domain/lab_test.dart';
import 'package:sunil_medical_store/features/medicines/domain/product.dart';
import 'package:sunil_medical_store/features/profile/domain/address.dart';
import 'package:sunil_medical_store/features/profile/presentation/providers/address_controller.dart';

/// Delivery fee and the subtotal above which delivery is free (rupees).
const int _deliveryFee = 40;
const int _freeDeliveryThreshold = 500;

/// The cart's line items, held in memory.
final cartProvider = NotifierProvider<CartController, List<CartItem>>(
  CartController.new,
);

class CartController extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => const [];

  /// Adds one unit of a medicine. No-op when the product is out of stock —
  /// the UI already disables the Add button, this is a defensive backstop.
  void addProduct(Product product) {
    if (product.isOutOfStock) return;
    _add(
      id: 'medicine-${product.id}',
      catalogId: product.id,
      title: product.name,
      subtitle: product.brand,
      price: product.price,
      kind: CartItemKind.medicine,
      requiresPrescription: product.requiresPrescription,
    );
  }

  /// Adds one unit of a lab test, scheduled for [scheduledDate] in the
  /// customer-chosen [timeSlot] (one of `kLabTestTimeSlots`).
  void addLabTest(LabTest test, {required DateTime scheduledDate, required String timeSlot}) => _add(
    id: 'labtest-${test.id}',
    catalogId: test.id,
    title: test.name,
    subtitle: test.labName,
    price: test.price,
    kind: CartItemKind.labTest,
    scheduledDate: scheduledDate,
    timeSlot: timeSlot,
  );

  void _add({
    required String id,
    required String catalogId,
    required String title,
    required String subtitle,
    required int price,
    required CartItemKind kind,
    bool requiresPrescription = false,
    DateTime? scheduledDate,
    String? timeSlot,
  }) {
    final index = state.indexWhere((i) => i.id == id);
    if (index >= 0) {
      // Re-adding an already-in-cart lab test updates its schedule to the
      // newly chosen date/slot (most-recent-wins) alongside the quantity bump.
      state = [
        for (var i = 0; i < state.length; i++)
          if (i == index)
            state[i].copyWith(
              quantity: state[i].quantity + 1,
              scheduledDate: scheduledDate,
              timeSlot: timeSlot,
            )
          else
            state[i],
      ];
    } else {
      state = [
        ...state,
        CartItem(
          id: id,
          catalogId: catalogId,
          title: title,
          subtitle: subtitle,
          price: price,
          kind: kind,
          quantity: 1,
          requiresPrescription: requiresPrescription,
          scheduledDate: scheduledDate,
          timeSlot: timeSlot,
        ),
      ];
    }
  }

  void increment(String id) {
    final index = state.indexWhere((i) => i.id == id);
    if (index >= 0) _setQuantity(index, state[index].quantity + 1);
  }

  /// Decrements a line; removes it when the quantity reaches zero.
  void decrement(String id) {
    final index = state.indexWhere((i) => i.id == id);
    if (index < 0) return;
    final next = state[index].quantity - 1;
    if (next <= 0) {
      remove(id);
    } else {
      _setQuantity(index, next);
    }
  }

  void remove(String id) {
    state = state.where((i) => i.id != id).toList();
  }

  void clear() => state = const [];

  void _setQuantity(int index, int quantity) {
    state = [
      for (var i = 0; i < state.length; i++)
        if (i == index) state[i].copyWith(quantity: quantity) else state[i],
    ];
  }
}

final promoRepositoryProvider = Provider<PromoRepository>((ref) {
  return ApiPromoRepository(ref.watch(dioProvider));
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return ApiOrderRepository(ref.watch(dioProvider));
});

/// The promo code currently applied to the cart (`null` if none).
final appliedPromoProvider = NotifierProvider<AppliedPromoController, PromoCode?>(
  AppliedPromoController.new,
);

class AppliedPromoController extends Notifier<PromoCode?> {
  @override
  PromoCode? build() => null;

  void apply(PromoCode promo) => state = promo;
  void clear() => state = null;
}

// --- Derived totals -------------------------------------------------------

final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).fold(0, (sum, i) => sum + i.quantity);
});

/// Whether any line in the cart requires a prescription — checkout gates
/// "Order Now" on a prescription being attached when this is true.
final cartRequiresPrescriptionProvider = Provider<bool>((ref) {
  return ref.watch(cartProvider).any((i) => i.requiresPrescription);
});

final cartSubtotalProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).fold(0, (sum, i) => sum + i.lineTotal);
});

final cartDiscountProvider = Provider<int>((ref) {
  final promo = ref.watch(appliedPromoProvider);
  final subtotal = ref.watch(cartSubtotalProvider);
  return promo?.discountFor(subtotal) ?? 0;
});

/// Whether the cart holds at least one pharmacy (medicine) item — the
/// dynamic delivery/platform fee system and the delivery-radius gate (see
/// checkout) are both pharmacy-only, per backlog #12's explicit scoping;
/// a lab-test-only cart keeps the legacy flat delivery rule unchanged and
/// never gets a platform fee.
final cartHasPharmacyItemsProvider = Provider<bool>((ref) {
  return ref.watch(cartProvider).any((i) => i.kind == CartItemKind.medicine);
});

/// The address checkout should price/gate against — the explicitly
/// selected one if the user changed it there, else the default address.
/// Also read by the Cart screen's price estimate (before an address is
/// ever explicitly chosen), where it naturally resolves to the default.
final selectedAddressIdProvider = NotifierProvider<SelectedAddressIdController, String?>(
  SelectedAddressIdController.new,
);

class SelectedAddressIdController extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String id) => state = id;
}

final selectedAddressProvider = Provider<Address?>((ref) {
  final addresses = ref.watch(addressesProvider).value ?? const <Address>[];
  final selectedId = ref.watch(selectedAddressIdProvider);
  if (selectedId != null) {
    for (final a in addresses) {
      if (a.id == selectedId) return a;
    }
  }
  for (final a in addresses) {
    if (a.isDefault) return a;
  }
  return addresses.isEmpty ? null : addresses.first;
});

int _legacyDeliveryFee(int subtotal) => subtotal >= _freeDeliveryThreshold ? 0 : _deliveryFee;

/// A fee amount paired with whether the admin has explicitly waived it.
/// [amount] is always "what it would cost" — even when [waived] is true —
/// so the UI can show it struck through rather than just disappearing.
/// [charged] is what actually gets added to the total.
class CartFeeLine {
  const CartFeeLine({required this.amount, required this.waived});

  final int amount;
  final bool waived;

  int get charged => waived ? 0 : amount;
}

/// Distance-tiered delivery fee (pharmacy carts only; see
/// [cartHasPharmacyItemsProvider]) computed from [selectedAddressProvider]'s
/// distance to the admin-configured store location. Falls back to the
/// legacy flat rule whenever it can't be computed — no delivery settings
/// configured/deployed yet, no tiers added, or the address has no captured
/// coordinates (manual entry, or pre-existing data — no backfill) — same
/// fail-open philosophy as the checkout radius gate.
final cartDeliveryFeeLineProvider = Provider<CartFeeLine>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  if (subtotal == 0) return const CartFeeLine(amount: 0, waived: false);
  if (!ref.watch(cartHasPharmacyItemsProvider)) {
    return CartFeeLine(amount: _legacyDeliveryFee(subtotal), waived: false);
  }

  final settings = ref.watch(deliverySettingsProvider).value;
  if (settings == null) {
    return CartFeeLine(amount: _legacyDeliveryFee(subtotal), waived: false);
  }

  final address = ref.watch(selectedAddressProvider);
  final distanceKm = (address?.latitude != null && address?.longitude != null)
      ? haversineKm(address!.latitude!, address.longitude!, settings.storeLatitude, settings.storeLongitude)
      : null;
  final tierFee = distanceKm != null ? settings.deliveryFeeForDistanceKm(distanceKm) : null;
  return CartFeeLine(amount: tierFee ?? _legacyDeliveryFee(subtotal), waived: settings.deliveryFeeWaived);
});

/// Single flat fee, pharmacy carts only — `0`/not-waived whenever there's
/// no pharmacy item, an empty cart, or delivery settings aren't
/// configured/deployed yet (fail open, same as delivery above).
final cartPlatformFeeLineProvider = Provider<CartFeeLine>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  if (subtotal == 0 || !ref.watch(cartHasPharmacyItemsProvider)) {
    return const CartFeeLine(amount: 0, waived: false);
  }
  final settings = ref.watch(deliverySettingsProvider).value;
  if (settings == null) return const CartFeeLine(amount: 0, waived: false);
  return CartFeeLine(amount: settings.platformFee, waived: settings.platformFeeWaived);
});

final cartDeliveryProvider = Provider<int>((ref) => ref.watch(cartDeliveryFeeLineProvider).charged);

final cartPlatformFeeProvider = Provider<int>((ref) => ref.watch(cartPlatformFeeLineProvider).charged);

final cartTotalProvider = Provider<int>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  final discount = ref.watch(cartDiscountProvider);
  final delivery = ref.watch(cartDeliveryProvider);
  final platformFee = ref.watch(cartPlatformFeeProvider);
  final total = subtotal - discount + delivery + platformFee;
  return total < 0 ? 0 : total;
});
