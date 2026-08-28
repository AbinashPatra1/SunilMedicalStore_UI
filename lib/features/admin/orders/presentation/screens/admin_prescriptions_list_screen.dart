import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/models/prescription.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/routes/app_routes.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/admin/orders/presentation/providers/admin_prescription_providers.dart';
import 'package:sunil_medical_store/features/admin/orders/presentation/widgets/admin_prescription_tile.dart';

/// Admin > Orders > Prescriptions sub-tab: every uploaded prescription
/// across every user, filterable by review status. Tap a row to approve or
/// reject.
class AdminPrescriptionsListScreen extends ConsumerWidget {
  const AdminPrescriptionsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusFilter = ref.watch(adminPrescriptionStatusFilterProvider);
    final async = ref.watch(adminPrescriptionsProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingLg,
              vertical: AppConstants.spacingSm,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: statusFilter == null,
                    onSelected: (_) =>
                        ref.read(adminPrescriptionStatusFilterProvider.notifier).set(null),
                  ),
                  for (final s in PrescriptionStatus.values) ...[
                    const SizedBox(width: AppConstants.spacingSm),
                    ChoiceChip(
                      label: Text(s.label),
                      selected: statusFilter == s,
                      onSelected: (_) =>
                          ref.read(adminPrescriptionStatusFilterProvider.notifier).set(s),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(error is ApiException ? error.message : 'Could not load prescriptions.'),
                    const SizedBox(height: AppConstants.spacingSm),
                    TextButton(
                      onPressed: () => ref.invalidate(adminPrescriptionsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (prescriptions) {
                if (prescriptions.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.spacingXl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.description_outlined, size: 56, color: theme.colorScheme.primary),
                          const SizedBox(height: AppConstants.spacingMd),
                          Text('No prescriptions', style: theme.textTheme.titleMedium),
                        ],
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(adminPrescriptionsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppConstants.spacingLg,
                      AppConstants.spacingSm,
                      AppConstants.spacingLg,
                      AppConstants.spacingLg,
                    ),
                    itemCount: prescriptions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppConstants.spacingSm),
                    itemBuilder: (context, index) {
                      final prescription = prescriptions[index];
                      return AdminPrescriptionTile(
                        prescription: prescription,
                        onTap: () => context.push(
                          '${AppRoutes.adminOrderPrescriptionEdit}/${prescription.id}',
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
