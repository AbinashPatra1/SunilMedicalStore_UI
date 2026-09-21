import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/models/order.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/features/cart/presentation/providers/cart_providers.dart';
import 'package:sunil_medical_store/features/medicines/presentation/providers/medicine_providers.dart';

/// What happened when an order's items were put back into the cart.
class ReorderResult {
  const ReorderResult({required this.added, required this.unavailable, required this.skippedLabTests});

  /// Medicine lines that went into the cart.
  final int added;

  /// Names of medicines that are out of stock or no longer sold.
  final List<String> unavailable;

  /// Lab-test lines left out — they need a fresh date and time slot.
  final int skippedLabTests;

  String get message {
    final String base;
    if (added == 0 && unavailable.isEmpty) {
      base = 'There is nothing to reorder from this order.';
    } else if (unavailable.isEmpty) {
      base = 'All items in this order are added to cart.';
    } else if (added == 0) {
      base = 'These items are out of stock: ${unavailable.join(', ')}. Nothing was added to cart.';
    } else {
      base = 'These items are out of stock: ${unavailable.join(', ')}. The rest of the items are added to cart.';
    }
    return skippedLabTests > 0
        ? '$base Lab tests were skipped — book them again from the Lab Tests tab.'
        : base;
  }
}

/// Whether [order] has anything [reorder] can act on (the backend has to
/// return `productId` per item for this to work).
bool canReorder(Order order) => order.items.any((i) => !i.isLabTest && i.productId != null);

/// Adds every medicine from [order] to the cart at its original quantity,
/// skipping (and reporting) ones that are out of stock or gone. Lab tests are
/// skipped. Throws [ApiException] on a network/server failure.
Future<ReorderResult> reorder(WidgetRef ref, Order order) async {
  final products = ref.read(productRepositoryProvider);
  final cart = ref.read(cartProvider.notifier);
  var added = 0;
  var skippedLabTests = 0;
  final unavailable = <String>[];

  for (final item in order.items) {
    if (item.isLabTest) {
      skippedLabTests++;
      continue;
    }
    final id = item.productId;
    if (id == null) continue;
    try {
      final product = await products.productById(id);
      if (product.isOutOfStock) {
        unavailable.add(item.name);
      } else {
        cart.addProduct(product, quantity: item.quantity);
        added++;
      }
    } on ApiException catch (e) {
      if (e.code == 'product_not_found') {
        unavailable.add(item.name);
      } else {
        rethrow;
      }
    }
  }
  return ReorderResult(added: added, unavailable: unavailable, skippedLabTests: skippedLabTests);
}
