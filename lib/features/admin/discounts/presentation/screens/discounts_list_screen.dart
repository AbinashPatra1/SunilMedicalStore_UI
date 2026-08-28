import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/routes/app_routes.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/admin/discounts/presentation/providers/discount_providers.dart';
import 'package:sunil_medical_store/features/admin/discounts/presentation/widgets/promo_code_tile.dart';
import 'package:sunil_medical_store/features/admin/presentation/widgets/admin_sign_out_button.dart';

/// Admin > Discounts: lists all promo codes. Tapping a row edits; the FAB
/// adds a new code.
class DiscountsListScreen extends ConsumerWidget {
  const DiscountsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(adminPromoCodesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discounts'),
        actions: const [AdminSignOutButton()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.adminDiscountAdd),
        icon: const Icon(Icons.add),
        label: const Text('Add code'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error is ApiException ? error.message : 'Could not load discounts.'),
              const SizedBox(height: AppConstants.spacingSm),
              TextButton(
                onPressed: () => ref.invalidate(adminPromoCodesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (promoCodes) {
          if (promoCodes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingXl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_offer_outlined, size: 56, color: theme.colorScheme.primary),
                    const SizedBox(height: AppConstants.spacingMd),
                    Text('No promo codes', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppConstants.spacingXs),
                    Text(
                      'Add a code with the button below.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminPromoCodesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.spacingLg,
                AppConstants.spacingSm,
                AppConstants.spacingLg,
                AppConstants.spacingXxl + AppConstants.spacingLg,
              ),
              itemCount: promoCodes.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppConstants.spacingSm),
              itemBuilder: (context, index) {
                final promoCode = promoCodes[index];
                return PromoCodeTile(
                  promoCode: promoCode,
                  onTap: () => context.push('${AppRoutes.adminDiscountEdit}/${promoCode.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
