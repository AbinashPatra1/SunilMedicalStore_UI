import 'package:sunil_medical_store/features/cart/domain/promo_code.dart';

/// Admin's view of a promo code: everything needed to run it, plus the
/// lifecycle/limit fields the customer-facing [PromoCode] doesn't carry.
class AdminPromoCode {
  const AdminPromoCode({
    required this.id,
    required this.code,
    required this.label,
    required this.type,
    required this.value,
    this.minOrder = 0,
    required this.active,
    this.expiresAt,
    this.maxRedemptions,
    this.perUserLimit,
    required this.redemptionCount,
  });

  final String id;
  final String code;
  final String label;
  final PromoType type;

  /// Percent (for [PromoType.percentage]) or rupees (for [PromoType.flat]).
  final int value;

  /// Minimum subtotal (rupees) required to use the code.
  final int minOrder;

  /// Admin can pause a code without deleting it.
  final bool active;

  /// After this date the code stops validating. `null` = never expires.
  final DateTime? expiresAt;

  /// Total redemptions allowed across all users. `null` = unlimited.
  final int? maxRedemptions;

  /// Redemptions allowed per user (e.g. `1` = one-time-per-user). `null` = unlimited.
  final int? perUserLimit;

  /// How many times this code has been successfully used so far (read-only,
  /// server-computed).
  final int redemptionCount;
}

/// Value object for create/update requests. Server assigns
/// [AdminPromoCode.id]/[AdminPromoCode.redemptionCount].
class PromoCodeInput {
  const PromoCodeInput({
    required this.code,
    required this.label,
    required this.type,
    required this.value,
    this.minOrder = 0,
    required this.active,
    this.expiresAt,
    this.maxRedemptions,
    this.perUserLimit,
  });

  final String code;
  final String label;
  final PromoType type;
  final int value;
  final int minOrder;
  final bool active;
  final DateTime? expiresAt;
  final int? maxRedemptions;
  final int? perUserLimit;
}
