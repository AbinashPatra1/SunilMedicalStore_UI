import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/auth/presentation/providers/auth_controller.dart';
import 'package:sunil_medical_store/features/profile/presentation/widgets/profile_option_tile.dart';

/// Profile tab: the signed-in user's details, dummy options, and Sign Out.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$label coming soon')));
  }

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
                radius: 32,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  user?.initials ?? '?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.name ?? 'Guest', style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppConstants.spacingXs),
                    Text(
                      user?.displayPhone ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (user != null) ...[
                      const SizedBox(height: AppConstants.spacingSm),
                      Chip(
                        label: Text(user.role.label),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingXl),
          ProfileOptionTile(
            icon: Icons.receipt_long_outlined,
            label: 'My Orders',
            onTap: () => _comingSoon(context, 'Orders'),
          ),
          ProfileOptionTile(
            icon: Icons.location_on_outlined,
            label: 'Addresses',
            onTap: () => _comingSoon(context, 'Addresses'),
          ),
          ProfileOptionTile(
            icon: Icons.help_outline,
            label: 'Help & Support',
            onTap: () => _comingSoon(context, 'Help & Support'),
          ),
          ProfileOptionTile(
            icon: Icons.info_outline,
            label: 'About',
            onTap: () => _comingSoon(context, 'About'),
          ),
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
