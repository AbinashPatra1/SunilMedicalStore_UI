import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/routes/app_routes.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/admin/appointments/presentation/providers/doctor_admin_providers.dart';
import 'package:sunil_medical_store/features/admin/appointments/presentation/widgets/admin_doctor_tile.dart';

/// Admin > Appointments > Doctors sub-tab: list all doctors, tap to edit,
/// FAB to add. Rendered inside the shared AdminAppointmentsShell.
class AdminDoctorsListScreen extends ConsumerWidget {
  const AdminDoctorsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminDoctorsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.adminDoctorAdd),
        icon: const Icon(Icons.person_add_alt_outlined),
        label: const Text('Add doctor'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error is ApiException ? error.message : 'Could not load doctors.'),
              const SizedBox(height: AppConstants.spacingSm),
              TextButton(
                onPressed: () => ref.invalidate(adminDoctorsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (doctors) {
          if (doctors.isEmpty) {
            return const _EmptyView();
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminDoctorsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.spacingLg,
                AppConstants.spacingMd,
                AppConstants.spacingLg,
                AppConstants.spacingXxl + AppConstants.spacingLg,
              ),
              itemCount: doctors.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppConstants.spacingSm),
              itemBuilder: (context, index) {
                final doctor = doctors[index];
                return AdminDoctorTile(
                  doctor: doctor,
                  onTap: () => context.push(
                    '${AppRoutes.adminDoctorEdit}/${doctor.id}',
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.medical_services_outlined, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: AppConstants.spacingMd),
            Text('No doctors yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppConstants.spacingXs),
            Text(
              'Add doctors with the button below so customers can book.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
