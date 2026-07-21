import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/auth/presentation/providers/auth_controller.dart';

/// Home screen for users with the admin role. Reached only via role-based
/// routing (see `app_router.dart`); customers are redirected away.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.admin_panel_settings_outlined,
                    color: theme.colorScheme.primary),
                const SizedBox(width: AppConstants.spacingSm),
                Text('Admin Console', style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              'Signed in as ${user?.name ?? 'admin'} (${user?.role.label ?? ''}).',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppConstants.spacingXl),
            Text(
              'Catalog, orders, and inventory management will be implemented '
              'here (see docs/ROADMAP.md, Phase 6).',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
