import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/routes/app_routes.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/admin/orders/domain/admin_order_repository.dart';
import 'package:sunil_medical_store/features/admin/orders/presentation/providers/admin_order_providers.dart';
import 'package:sunil_medical_store/features/admin/orders/presentation/widgets/admin_order_tile.dart';
import 'package:sunil_medical_store/features/admin/orders/presentation/widgets/order_filter_sheet.dart';
import 'package:sunil_medical_store/features/admin/presentation/widgets/admin_sign_out_button.dart';

/// Admin > Orders tab: every order across every user, with search + filter
/// sheet. Tap a row to view/edit status.
class AdminOrdersListScreen extends ConsumerStatefulWidget {
  const AdminOrdersListScreen({super.key});

  @override
  ConsumerState<AdminOrdersListScreen> createState() => _AdminOrdersListScreenState();
}

class _AdminOrdersListScreenState extends ConsumerState<AdminOrdersListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(adminOrderFiltersProvider).search ?? '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateSearch(String value) {
    final current = ref.read(adminOrderFiltersProvider);
    ref.read(adminOrderFiltersProvider.notifier).set(
      OrderFilters(
        search: value.trim().isEmpty ? null : value.trim(),
        status: current.status,
        dateFrom: current.dateFrom,
        dateTo: current.dateTo,
      ),
    );
  }

  Future<void> _openFilters() async {
    final current = ref.read(adminOrderFiltersProvider);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => OrderFilterSheet(
        initial: current,
        onApply: (next) => ref.read(adminOrderFiltersProvider.notifier).set(next),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filters = ref.watch(adminOrderFiltersProvider);
    final async = ref.watch(adminOrdersProvider);
    final hasFilters = !filters.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: const [AdminSignOutButton()],
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
                      hintText: 'Search order #, user or phone',
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
                    Text(error is ApiException ? error.message : 'Could not load orders.'),
                    const SizedBox(height: AppConstants.spacingSm),
                    TextButton(
                      onPressed: () => ref.invalidate(adminOrdersProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (orders) {
                if (orders.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.spacingXl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 56, color: theme.colorScheme.primary),
                          const SizedBox(height: AppConstants.spacingMd),
                          Text(
                            hasFilters ? 'No matches' : 'No orders yet',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(adminOrdersProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppConstants.spacingLg,
                      AppConstants.spacingSm,
                      AppConstants.spacingLg,
                      AppConstants.spacingLg,
                    ),
                    itemCount: orders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppConstants.spacingSm),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return AdminOrderTile(
                        order: order,
                        onTap: () => context.push('${AppRoutes.adminOrderEdit}/${order.id}'),
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
