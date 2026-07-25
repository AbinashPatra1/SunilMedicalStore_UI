import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/routes/app_routes.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/profile/domain/address.dart';
import 'package:sunil_medical_store/features/profile/presentation/providers/address_controller.dart';

/// Profile > Addresses: list of saved addresses with the ability to set a
/// default and add a new one.
class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  IconData _icon(AddressType type) => switch (type) {
    AddressType.home => Icons.home_outlined,
    AddressType.work => Icons.work_outline,
    AddressType.other => Icons.location_on_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final addresses = ref.watch(addressesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Addresses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.profileAddAddress),
        icon: const Icon(Icons.add),
        label: const Text('Add address'),
      ),
      body: addresses.isEmpty
          ? const Center(child: Text('No addresses saved yet.'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.spacingLg,
                AppConstants.spacingLg,
                AppConstants.spacingLg,
                AppConstants.spacingXxl + AppConstants.spacingLg,
              ),
              itemCount: addresses.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppConstants.spacingMd),
              itemBuilder: (context, index) {
                final address = addresses[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.spacingMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(_icon(address.type), size: 20, color: theme.colorScheme.primary),
                            const SizedBox(width: AppConstants.spacingSm),
                            Text(address.type.label, style: theme.textTheme.titleSmall),
                            const SizedBox(width: AppConstants.spacingSm),
                            if (address.isDefault)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingSm, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                                ),
                                child: Text('Default', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.spacingSm),
                        Text(address.formatted, style: theme.textTheme.bodyMedium),
                        if (!address.isDefault) ...[
                          const SizedBox(height: AppConstants.spacingSm),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () => ref.read(addressesProvider.notifier).setDefault(address.id),
                              child: const Text('Set as default'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
