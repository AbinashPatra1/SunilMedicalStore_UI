import 'package:sunil_medical_store/features/admin/discounts/domain/admin_promo_code.dart';

/// Admin-side CRUD over promo codes.
///
/// The customer-facing `PromoRepository` only validates a code against a
/// subtotal (`POST /promo-codes/validate`) — this is the separate
/// administration surface, mirroring the `InventoryRepository` /
/// `ProductRepository` split.
abstract interface class DiscountRepository {
  /// All promo codes, newest first.
  Future<List<AdminPromoCode>> list();

  /// Single promo code by id.
  Future<AdminPromoCode> getById(String id);

  /// Creates a new promo code. Returns the server-assigned id/state.
  Future<AdminPromoCode> create(PromoCodeInput input);

  /// Updates an existing promo code. Returns the refreshed code.
  Future<AdminPromoCode> update(String id, PromoCodeInput input);

  Future<void> delete(String id);
}
