import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/admin/discounts/domain/admin_promo_code.dart';
import 'package:sunil_medical_store/features/cart/domain/promo_code.dart';
import 'package:sunil_medical_store/features/profile/presentation/widgets/status_chip.dart';

/// Admin-side promo code row: code + label + rule summary + active/expiry/
/// usage badges. Tap the whole tile to edit.
class PromoCodeTile extends StatelessWidget {
  const PromoCodeTile({super.key, required this.promoCode, required this.onTap});

  final AdminPromoCode promoCode;
  final VoidCallback onTap;

  bool get _isExpired =>
      promoCode.expiresAt != null && promoCode.expiresAt!.isBefore(DateTime.now());

  bool get _isExhausted =>
      promoCode.maxRedemptions != null && promoCode.redemptionCount >= promoCode.maxRedemptions!;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueLabel = promoCode.type == PromoType.percentage
        ? '${promoCode.value}% off'
        : '₹${promoCode.value} off';
    final live = promoCode.active && !_isExpired && !_isExhausted;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(promoCode.code, style: theme.textTheme.titleSmall),
                    Text(
                      promoCode.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingSm),
                    Wrap(
                      spacing: AppConstants.spacingSm,
                      runSpacing: AppConstants.spacingXs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(valueLabel, style: theme.textTheme.bodyMedium),
                        if (promoCode.minOrder > 0)
                          Text(
                            'min ₹${promoCode.minOrder}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        if (promoCode.expiresAt != null)
                          Text(
                            'exp ${DateFormat('d MMM yyyy').format(promoCode.expiresAt!)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _isExpired ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    if (promoCode.maxRedemptions != null || promoCode.perUserLimit != null) ...[
                      const SizedBox(height: AppConstants.spacingXs),
                      Text(
                        '${promoCode.redemptionCount}'
                        '${promoCode.maxRedemptions != null ? '/${promoCode.maxRedemptions}' : ''} used'
                        '${promoCode.perUserLimit != null ? ' • max ${promoCode.perUserLimit}/user' : ''}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              StatusChip(
                label: live ? 'Active' : (_isExpired ? 'Expired' : (_isExhausted ? 'Exhausted' : 'Inactive')),
                positive: live,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
