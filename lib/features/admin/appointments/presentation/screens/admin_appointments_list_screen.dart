import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/routes/app_routes.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/admin/appointments/domain/admin_appointment_repository.dart';
import 'package:sunil_medical_store/features/admin/appointments/presentation/providers/admin_appointment_providers.dart';
import 'package:sunil_medical_store/features/admin/appointments/presentation/widgets/admin_appointment_tile.dart';
import 'package:sunil_medical_store/features/admin/appointments/presentation/widgets/appointment_filter_sheet.dart';

/// Admin > Appointments > Appointments sub-tab: list of every appointment
/// across every user, with search + filter sheet + create-on-behalf FAB.
class AdminAppointmentsListScreen extends ConsumerStatefulWidget {
  const AdminAppointmentsListScreen({super.key});

  @override
  ConsumerState<AdminAppointmentsListScreen> createState() =>
      _AdminAppointmentsListScreenState();
}

class _AdminAppointmentsListScreenState
    extends ConsumerState<AdminAppointmentsListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(adminAppointmentFiltersProvider).search ?? '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateSearch(String value) {
    final current = ref.read(adminAppointmentFiltersProvider);
    ref.read(adminAppointmentFiltersProvider.notifier).set(
      AppointmentFilters(
        search: value.trim().isEmpty ? null : value.trim(),
        status: current.status,
        doctorId: current.doctorId,
        dateFrom: current.dateFrom,
        dateTo: current.dateTo,
        weekday: current.weekday,
      ),
    );
  }

  Future<void> _openFilters() async {
    final current = ref.read(adminAppointmentFiltersProvider);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AppointmentFilterSheet(
        initial: current,
        onApply: (next) => ref.read(adminAppointmentFiltersProvider.notifier).set(next),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filters = ref.watch(adminAppointmentFiltersProvider);
    final async = ref.watch(adminAppointmentsProvider);
    final hasFilters = !filters.isEmpty;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.adminAppointmentNew),
        icon: const Icon(Icons.add),
        label: const Text('New appointment'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingLg,
              vertical: AppConstants.spacingSm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: _updateSearch,
                    decoration: InputDecoration(
                      hintText: 'Search user or doctor',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _updateSearch('');
                              },
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingSm),
                Badge(
                  isLabelVisible: hasFilters,
                  child: IconButton.filledTonal(
                    onPressed: _openFilters,
                    icon: const Icon(Icons.tune),
                    tooltip: 'Filters',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(error is ApiException ? error.message : 'Could not load appointments.'),
                    const SizedBox(height: AppConstants.spacingSm),
                    TextButton(
                      onPressed: () => ref.invalidate(adminAppointmentsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (appointments) {
                if (appointments.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.spacingXl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_month_outlined, size: 56, color: theme.colorScheme.primary),
                          const SizedBox(height: AppConstants.spacingMd),
                          Text(
                            hasFilters ? 'No matches' : 'No appointments yet',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(adminAppointmentsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppConstants.spacingLg,
                      AppConstants.spacingSm,
                      AppConstants.spacingLg,
                      AppConstants.spacingXxl + AppConstants.spacingLg,
                    ),
                    itemCount: appointments.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppConstants.spacingSm),
                    itemBuilder: (context, index) {
                      final appointment = appointments[index];
                      return AdminAppointmentTile(
                        appointment: appointment,
                        onTap: () => context.push(
                          '${AppRoutes.adminAppointmentEdit}/${appointment.id}',
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
