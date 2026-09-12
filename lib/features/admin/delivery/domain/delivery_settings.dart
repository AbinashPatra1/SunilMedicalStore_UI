/// One band of the distance-tiered delivery fee: charged when the distance
/// from the store is at most [maxDistanceKm] and no earlier (smaller) tier
/// already matched. Orders beyond the store's configured radius are already
/// blocked entirely at checkout, so tiers only need to cover `[0, radiusKm]`.
class DeliveryFeeTier {
  const DeliveryFeeTier({required this.maxDistanceKm, required this.fee});

  final double maxDistanceKm;
  final int fee;
}

/// The store's reference point + delivery radius + the pharmacy-only
/// dynamic fee configuration (backlog #11/#12). Lab tests and appointments
/// are never gated or fee-adjusted by any of this.
class DeliverySettings {
  const DeliverySettings({
    required this.storeLatitude,
    required this.storeLongitude,
    required this.radiusKm,
    this.deliveryFeeTiers = const [],
    this.deliveryFeeWaived = false,
    this.platformFee = 0,
    this.platformFeeWaived = false,
  });

  final double storeLatitude;
  final double storeLongitude;
  final double radiusKm;

  /// Distance-tiered delivery fee. Empty means "not configured yet" —
  /// checkout falls back to the legacy flat ₹40/free-over-₹500 rule.
  final List<DeliveryFeeTier> deliveryFeeTiers;

  /// Admin override: delivery is always free regardless of tiers, shown
  /// struck through on the price breakdown rather than just omitted.
  final bool deliveryFeeWaived;

  /// Single flat fee, charged once per pharmacy order regardless of distance.
  final int platformFee;
  final bool platformFeeWaived;

  /// The delivery fee for [distanceKm], or `null` if no tiers are
  /// configured (caller should fall back to a legacy default in that case).
  /// Tiers needn't arrive pre-sorted — this sorts ascending by
  /// [DeliveryFeeTier.maxDistanceKm] before matching.
  int? deliveryFeeForDistanceKm(double distanceKm) {
    if (deliveryFeeTiers.isEmpty) return null;
    final sorted = [...deliveryFeeTiers]..sort((a, b) => a.maxDistanceKm.compareTo(b.maxDistanceKm));
    for (final tier in sorted) {
      if (distanceKm <= tier.maxDistanceKm) return tier.fee;
    }
    return sorted.last.fee;
  }
}
