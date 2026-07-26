import 'package:sunil_medical_store/features/cart/domain/promo_code.dart';
import 'package:sunil_medical_store/features/cart/domain/promo_repository.dart';

/// In-memory mock of [PromoRepository] with a few demo codes.
class MockPromoRepository implements PromoRepository {
  static const _codes = <String, PromoCode>{
    'SAVE10': PromoCode(code: 'SAVE10', label: '10% off your order', type: PromoType.percentage, value: 10),
    'FLAT50': PromoCode(code: 'FLAT50', label: '₹50 off above ₹300', type: PromoType.flat, value: 50, minOrder: 300),
    'NEW100': PromoCode(code: 'NEW100', label: '₹100 off above ₹500', type: PromoType.flat, value: 100, minOrder: 500),
  };

  @override
  Future<PromoCode> validate(String code, {required int subtotal}) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final promo = _codes[code.trim().toUpperCase()];
    if (promo == null) {
      throw const PromoException('Invalid promo code.');
    }
    if (subtotal < promo.minOrder) {
      throw PromoException('Add ₹${promo.minOrder - subtotal} more to use this code.');
    }
    return promo;
  }
}
