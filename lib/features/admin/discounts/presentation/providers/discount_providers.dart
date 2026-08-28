import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_client.dart';
import 'package:sunil_medical_store/features/admin/discounts/data/api_discount_repository.dart';
import 'package:sunil_medical_store/features/admin/discounts/domain/admin_promo_code.dart';
import 'package:sunil_medical_store/features/admin/discounts/domain/discount_repository.dart';

/// Provides the [DiscountRepository] implementation (real API).
final discountRepositoryProvider = Provider<DiscountRepository>((ref) {
  return ApiDiscountRepository(ref.watch(dioProvider));
});

/// All promo codes.
final adminPromoCodesProvider = FutureProvider<List<AdminPromoCode>>((ref) {
  return ref.watch(discountRepositoryProvider).list();
});

/// A single promo code for the edit form. `null` id means Add mode.
final adminPromoCodeByIdProvider = FutureProvider.family<AdminPromoCode, String>((ref, id) {
  return ref.watch(discountRepositoryProvider).getById(id);
});
