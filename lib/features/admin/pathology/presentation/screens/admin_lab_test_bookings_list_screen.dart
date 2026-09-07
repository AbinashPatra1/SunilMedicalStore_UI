import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/routes/app_routes.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/admin/pathology/domain/admin_lab_test_repository.dart';
import 'package:sunil_medical_store/features/admin/pathology/presentation/providers/admin_lab_test_providers.dart';
import 'package:sunil_medical_store/features/admin/pathology/presentation/widgets/admin_lab_test_tile.dart';
import 'package:sunil_medical_store/features/admin/pathology/presentation/widgets/lab_test_booking_filter_sheet.dart';

/// Admin > Orders > Pathology sub-tab: every lab-test booking across every
/// user, with search + filter sheet. Tap a row to view/advance status.
class AdminLabTestBookingsListScreen extends ConsumerStatefulWidget {
  const AdminLabTestBookingsListScreen({super.key});

  @override
  ConsumerState<AdminLabTestBookingsListScreen> createState() => _AdminLabTestBookingsListScreenState();
}

class _AdminLabTestBookingsListScreenState extends ConsumerState<AdminLabTestBookingsListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(adminLabTestFiltersProvider).search ?? '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateSearch(String value) {
    final current = ref.read(adminLabTestFiltersProvider);
    ref.read(adminLabTestFiltersProvider.notifier).set(
      LabTestBookingFilters(
        search: value.trim().isEmpty ? null : value.trim(),
        status: current.status,
        dateFrom: current.dateFrom,
        dateTo: current.dateTo,
      ),
    );
  }

  Future<void> _openFilters() async {
    final current = ref.read(adminLabTestFiltersProvider);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => LabTestBookingFilterSheet(
        initial: current,
        onApply: (next) => ref.read(adminLabTestFiltersProvider.notifier).set(next),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filters = ref.watch(adminLabTestFiltersProvider);
    final async = ref.watch(adminLabTestBookingsProvider);
    final hasFilters = !filters.isEmpty;

    return Scaffold(
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
                      hintText: 'Search test, user or phone',
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
                    Text(error is ApiException ? error.message : 'Could not load bookings.'),
                    const SizedBox(height: AppConstants.spacingSm),
                    TextButton(
                      onPressed: () => ref.invalidate(adminLabTestBookingsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (bookings) {
                if (bookings.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.spacingXl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.biotech_outlined, size: 56, color: theme.colorScheme.primary),
                          const SizedBox(height: AppConstants.spacingMd),
                          Text(
                            hasFilters ? 'No matches' : 'No lab-test bookings yet',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(adminLabTestBookingsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppConstants.spacingLg,
                      AppConstants.spacingSm,
                      AppConstants.spacingLg,
                      AppConstants.spacingLg,
                    ),
                    itemCount: bookings.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppConstants.spacingSm),
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      return AdminLabTestTile(
                        booking: booking,
                        onTap: () => context.push('${AppRoutes.adminPathologyEdit}/${booking.id}'),
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
