import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/routes/app_routes.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/auth/presentation/providers/auth_controller.dart';
import 'package:sunil_medical_store/features/dashboard/presentation/widgets/dashboard_nav_card.dart';

/// Customer home screen shown after a non-admin signs in.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
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
          Text('Welcome, ${user?.name ?? 'Guest'}', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppConstants.spacingXs),
          Text(
            user?.email ?? '',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppConstants.spacingXl),
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
