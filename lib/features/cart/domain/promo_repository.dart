import 'package:sunil_medical_store/features/cart/domain/promo_code.dart';

/// Validates promo codes, implemented by the data layer.
abstract interface class PromoRepository {
  /// Returns the [PromoCode] for [code] if it's valid for the given [subtotal].
  /// Throws [PromoException] otherwise.
  Future<PromoCode> validate(String code, {required int subtotal});
}

/// User-presentable failure while applying a promo code.
class PromoException implements Exception {
  const PromoException(this.message);

  final String message;

  @override
  String toString() => 'PromoException: $message';
}
