import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_client.dart';
import 'package:sunil_medical_store/features/cart/data/api_order_repository.dart';
import 'package:sunil_medical_store/features/cart/data/api_promo_repository.dart';
import 'package:sunil_medical_store/features/cart/domain/cart_item.dart';
import 'package:sunil_medical_store/features/cart/domain/order_repository.dart';
import 'package:sunil_medical_store/features/cart/domain/promo_code.dart';
import 'package:sunil_medical_store/features/cart/domain/promo_repository.dart';
import 'package:sunil_medical_store/features/lab_tests/domain/lab_test.dart';
import 'package:sunil_medical_store/features/medicines/domain/product.dart';

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

final cartDeliveryProvider = Provider<int>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  if (subtotal == 0 || subtotal >= _freeDeliveryThreshold) return 0;
  return _deliveryFee;
});

final cartTotalProvider = Provider<int>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  final discount = ref.watch(cartDiscountProvider);
  final delivery = ref.watch(cartDeliveryProvider);
  final total = subtotal - discount + delivery;
  return total < 0 ? 0 : total;
});
