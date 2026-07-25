import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/routes/app_routes.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/auth/presentation/providers/auth_controller.dart';
import 'package:sunil_medical_store/features/profile/presentation/widgets/profile_option_tile.dart';

/// Profile tab: the customer's header, a menu of sections, and Sign Out.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  user?.initials ?? '?',
                  style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                ),
              ),
              const SizedBox(width: AppConstants.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.name ?? 'Guest', style: theme.textTheme.titleLarge),
                    Text(
                      user?.displayPhone ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingXl),
          ProfileOptionTile(icon: Icons.person_outline, label: 'Account', onTap: () => context.push(AppRoutes.profileAccount)),
          ProfileOptionTile(icon: Icons.calendar_month_outlined, label: 'Appointments', onTap: () => context.push(AppRoutes.profileAppointments)),
          ProfileOptionTile(icon: Icons.receipt_long_outlined, label: 'Orders', onTap: () => context.push(AppRoutes.profileOrders)),
          ProfileOptionTile(icon: Icons.biotech_outlined, label: 'Lab Tests', onTap: () => context.push(AppRoutes.profileLabTests)),
          ProfileOptionTile(icon: Icons.location_on_outlined, label: 'Addresses', onTap: () => context.push(AppRoutes.profileAddresses)),
          ProfileOptionTile(icon: Icons.account_balance_wallet_outlined, label: 'Payment Methods', onTap: () => context.push(AppRoutes.profilePayments)),
          const SizedBox(height: AppConstants.spacingLg),
          OutlinedButton.icon(
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
