import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sunil_medical_store/features/cart/presentation/providers/cart_providers.dart';
import 'package:sunil_medical_store/features/medicines/domain/product.dart';

void main() {
  const rx = Product(id: 'rx', name: 'Rx drug', brand: 'B', category: 'C', price: 10, requiresPrescription: true, stock: 5);
  const otc = Product(id: 'otc', name: 'OTC', brand: 'B', category: 'C', price: 10, stock: 5);
  const otc2 = Product(id: 'otc2', name: 'OTC 2', brand: 'B', category: 'C', price: 10, stock: 5);

  test('prescription flag clears once every Rx item is removed', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final cart = container.read(cartProvider.notifier);

    cart.addProduct(rx);
    cart.addProduct(otc);
    cart.addProduct(otc2);
    expect(container.read(cartRequiresPrescriptionProvider), isTrue);

    cart.increment('medicine-otc');
    cart.remove('medicine-rx');
    cart.remove('medicine-otc2');
    expect(container.read(cartProvider).map((i) => i.id), ['medicine-otc']);
    expect(container.read(cartRequiresPrescriptionProvider), isFalse);
  });

  test('flag stays set while any Rx item remains, even after quantity changes', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final cart = container.read(cartProvider.notifier);

    cart.addProduct(rx);
    cart.addProduct(otc);
    cart.increment('medicine-rx');
    cart.decrement('medicine-rx');
    cart.remove('medicine-otc');
    expect(container.read(cartRequiresPrescriptionProvider), isTrue);
  });
}
