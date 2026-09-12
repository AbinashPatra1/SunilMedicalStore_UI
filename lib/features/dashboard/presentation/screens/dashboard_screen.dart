import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/routes/app_routes.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/auth/presentation/providers/auth_controller.dart';
import 'package:sunil_medical_store/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:sunil_medical_store/features/dashboard/presentation/widgets/category_grid.dart';
import 'package:sunil_medical_store/features/dashboard/presentation/widgets/home_search_bar.dart';
import 'package:sunil_medical_store/features/dashboard/presentation/widgets/pharmacy_action_buttons.dart';
import 'package:sunil_medical_store/features/dashboard/presentation/widgets/promo_banner.dart';
import 'package:sunil_medical_store/features/dashboard/presentation/widgets/suggested_products.dart';
import 'package:sunil_medical_store/features/profile/domain/address.dart';
import 'package:sunil_medical_store/features/profile/presentation/providers/address_controller.dart';

/// Customer landing page (Pharmacy tab) shown after a non-admin signs in.
///
/// Dummy content for now — categories come from [homeCategoriesProvider],
/// products from the medicines providers, and image search is a placeholder
/// until that feature is built. Prescription upload and the search bar are
/// real — see `features/prescriptions` and `SearchScreen`.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$label coming soon')));
  }

  /// Route to the medicines list filtered by [category].
  String _categoryRoute(String category) =>
      '${AppRoutes.medicines}?category=${Uri.encodeComponent(category)}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).user;
    final categoriesAsync = ref.watch(homeCategoriesProvider);
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

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppConstants.spacingLg,
        title: Row(
          children: [
            Icon(Icons.local_pharmacy_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: AppConstants.spacingSm),
            const Text(AppConstants.appName),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        children: [
          Text('Hello, ${user?.name ?? 'there'} 👋', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppConstants.spacingXs),
          if (deliveringToArea != null) ...[
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: AppConstants.spacingXs),
                Text(
                  'Delivering to $deliveringToArea',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
          PharmacyActionButtons(
            onSearchByImage: () => _comingSoon(context, 'Image search'),
            onUploadPrescription: () => context.push(AppRoutes.prescriptions),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          HomeSearchBar(onTap: () => context.push(AppRoutes.search)),
          const SizedBox(height: AppConstants.spacingLg),
          PromoBanner(onTap: () => context.go(AppRoutes.medicines)),
          const SizedBox(height: AppConstants.spacingLg),
          Text('Shop by category', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppConstants.spacingMd),
          categoriesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppConstants.spacingLg),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => Text(
              'Could not load categories.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            data: (categories) => CategoryGrid(
              categories: categories,
              onTap: (category) => context.go(_categoryRoute(category.label)),
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          const SuggestedProducts(),
        ],
      ),
    );
  }
}
