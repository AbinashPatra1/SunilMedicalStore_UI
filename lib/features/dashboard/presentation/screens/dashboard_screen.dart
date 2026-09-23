import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/routes/app_routes.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/auth/presentation/providers/auth_controller.dart';
import 'package:sunil_medical_store/features/dashboard/presentation/widgets/category_grid.dart';
import 'package:sunil_medical_store/features/dashboard/presentation/widgets/home_banner_carousel.dart';
import 'package:sunil_medical_store/features/dashboard/presentation/widgets/home_search_bar.dart';
import 'package:sunil_medical_store/features/dashboard/presentation/widgets/suggested_products.dart';
import 'package:sunil_medical_store/features/medicines/domain/product_category.dart';
import 'package:sunil_medical_store/features/profile/domain/address.dart';
import 'package:sunil_medical_store/features/profile/presentation/providers/address_controller.dart';
import 'package:sunil_medical_store/core/widgets/refresh_on_focus.dart';
import 'package:sunil_medical_store/features/medicines/presentation/providers/medicine_providers.dart';

/// Customer landing page (Pharmacy tab) shown after a non-admin signs in.
///
/// Dummy content for now — products from the medicines providers, and image
/// search is a placeholder until that feature is built. Prescription upload
/// and the search bar are real — see `features/prescriptions` and
/// `SearchScreen`. Categories are the fixed [ProductCategory] catalog (see
/// backlog #14).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  /// Route to the medicines list filtered by [category].
  String _categoryRoute(ProductCategory category) =>
      '${AppRoutes.medicines}?category=${Uri.encodeComponent(category.label)}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).user;
    final addresses = ref.watch(addressesProvider).value ?? const <Address>[];
    Address? defaultAddress;
    for (final a in addresses) {
      if (a.isDefault) {
        defaultAddress = a;
        break;
      }
    }
    defaultAddress ??= addresses.isNotEmpty ? addresses.first : null;
    final deliveringToArea = defaultAddress?.area ?? defaultAddress?.city;

    return RefreshOnFocus(
      onRefresh: () { refreshIfIdle(ref, suggestedProductsProvider); },
      child: Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          children: [
            Text(
              'Hello, ${user?.name ?? 'there'} 👋',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppConstants.spacingXs),
            if (deliveringToArea != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppConstants.spacingXs),
                  Text(
                    'Delivering to $deliveringToArea',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingXs),
            ],
            Text(
              'How can we help you today?',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),
            Row(
              children: [
                Expanded(
                  child: HomeSearchBar(
                    onTap: () => context.push(AppRoutes.search),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingSm),
                IconButton.filledTonal(
                  onPressed: () => context.push(AppRoutes.prescriptions),
                  tooltip: 'Prescription',
                  icon: const Icon(Icons.upload_file_outlined),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingLg),
            HomeBannerCarousel(onTap: () => context.go(AppRoutes.medicines)),
            const SizedBox(height: AppConstants.spacingLg),
            Text('Shop by category', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppConstants.spacingMd),
            CategoryGrid(
              categories: homeFeaturedCategories,
              onTap: (category) => context.go(_categoryRoute(category)),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.categories),
                icon: const Icon(Icons.apps_outlined),
                label: const Text('Show All Categories'),
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),
            const SuggestedProducts(),
          ],
        ),
      ),
    ),
    );
  }
}
