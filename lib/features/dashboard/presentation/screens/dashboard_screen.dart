import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/routes/app_routes.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/auth/presentation/providers/auth_controller.dart';
import 'package:sunil_medical_store/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:sunil_medical_store/features/dashboard/presentation/widgets/category_grid.dart';
import 'package:sunil_medical_store/features/dashboard/presentation/widgets/dashboard_nav_card.dart';
import 'package:sunil_medical_store/features/dashboard/presentation/widgets/home_search_bar.dart';
import 'package:sunil_medical_store/features/dashboard/presentation/widgets/promo_banner.dart';

/// Customer landing page shown after a non-admin signs in.
///
/// Dummy content for now — categories come from [homeCategoriesProvider] and
/// the search/promo actions are placeholders until those features are built.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$label coming soon')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).user;
    final categories = ref.watch(homeCategoriesProvider);

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
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        children: [
          Text('Hello, ${user?.name ?? 'there'} 👋', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppConstants.spacingXs),
          Text(
            'How can we help you today?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          HomeSearchBar(onTap: () => _comingSoon(context, 'Search')),
          const SizedBox(height: AppConstants.spacingLg),
          PromoBanner(onTap: () => context.go(AppRoutes.medicines)),
          const SizedBox(height: AppConstants.spacingLg),
          Text('Shop by category', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppConstants.spacingMd),
          CategoryGrid(
            categories: categories,
            onTap: (_) => context.go(AppRoutes.medicines),
          ),
          const SizedBox(height: AppConstants.spacingLg),
          Text('Quick actions', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppConstants.spacingMd),
          DashboardNavCard(
            icon: Icons.medication_outlined,
            label: 'Browse Medicines',
            onTap: () => context.go(AppRoutes.medicines),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          DashboardNavCard(
            icon: Icons.shopping_cart_outlined,
            label: 'My Cart',
            onTap: () => context.go(AppRoutes.cart),
          ),
        ],
      ),
    );
  }
}
