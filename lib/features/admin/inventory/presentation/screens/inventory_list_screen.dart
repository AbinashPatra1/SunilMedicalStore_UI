import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/routes/app_routes.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/admin/inventory/presentation/providers/inventory_filters_provider.dart';
import 'package:sunil_medical_store/features/admin/inventory/presentation/providers/inventory_providers.dart';
import 'package:sunil_medical_store/features/admin/inventory/presentation/widgets/inventory_item_tile.dart';
import 'package:sunil_medical_store/features/admin/presentation/widgets/admin_sign_out_button.dart';
import 'package:sunil_medical_store/features/medicines/domain/product.dart';
import 'package:sunil_medical_store/features/medicines/domain/product_category.dart';

/// Admin > Inventory: lists all products (in and out of stock). The top bar
/// shows the first 5 categories as quick-filter chips plus a fixed filter
/// icon opening [AdminInventoryFilterScreen] for the full category/type/
/// search selection. Tapping a row edits; the FAB adds a new product.
class InventoryListScreen extends ConsumerStatefulWidget {
  const InventoryListScreen({super.key});

  @override
  ConsumerState<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends ConsumerState<InventoryListScreen> {
  bool _inStockOnly = false;

  bool _matchesSearch(Product product, String query) {
    final q = query.toLowerCase();
    return product.name.toLowerCase().contains(q) ||
        product.category.toLowerCase().contains(q) ||
        (product.type?.label.toLowerCase().contains(q) ?? false) ||
        (product.composition?.toLowerCase().contains(q) ?? false) ||
        product.ingredients.any((i) => i.toLowerCase().contains(q));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filters = ref.watch(adminInventoryFiltersProvider);
    final productsAsync = ref.watch(adminInventoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            tooltip: 'Bulk import',
            icon: const Icon(Icons.upload_file_outlined),
            onPressed: () => context.push(AppRoutes.adminInventoryImport),
          ),
          const AdminSignOutButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.adminInventoryAdd),
        icon: const Icon(Icons.add),
        label: const Text('Add product'),
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
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: filters.category == null,
                          onSelected: (_) => ref
                              .read(adminInventoryFiltersProvider.notifier)
                              .apply(filters.withCategory(null)),
                        ),
                        for (final c in adminTopBarCategories) ...[
                          const SizedBox(width: AppConstants.spacingSm),
                          ChoiceChip(
                            label: Text(c.label),
                            selected: filters.category == c,
                            onSelected: (_) => ref
                                .read(adminInventoryFiltersProvider.notifier)
                                .apply(filters.withCategory(c)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Filter',
                  icon: Badge(
                    isLabelVisible: filters.isActive,
                    smallSize: 8,
                    child: const Icon(Icons.tune),
                  ),
                  onPressed: () => context.push(AppRoutes.adminInventoryFilter),
                ),
              ],
            ),
          ),
          // In-stock toggle.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingLg),
            child: Row(
              children: [
                Text('In stock only', style: theme.textTheme.bodyMedium),
                const Spacer(),
                Switch(
                  value: _inStockOnly,
                  onChanged: (v) => setState(() => _inStockOnly = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorView(
                message: error is ApiException ? error.message : 'Could not load inventory.',
                onRetry: () => ref.invalidate(adminInventoryListProvider),
              ),
              data: (products) {
                var visible = _inStockOnly ? products.where((p) => p.stock > 0).toList() : products;
                if (filters.type != null) {
                  visible = visible.where((p) => p.type == filters.type).toList();
                }
                if (filters.search.isNotEmpty) {
                  visible = visible.where((p) => _matchesSearch(p, filters.search)).toList();
                }
                if (visible.isEmpty) {
                  return const _EmptyView();
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(adminInventoryListProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppConstants.spacingLg,
                      AppConstants.spacingSm,
                      AppConstants.spacingLg,
                      AppConstants.spacingXxl + AppConstants.spacingLg,
                    ),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppConstants.spacingSm),
                    itemBuilder: (context, index) {
                      final product = visible[index];
                      return InventoryItemTile(
                        product: product,
                        onTap: () => context.push(
                          '${AppRoutes.adminInventoryEdit}/${product.id}',
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
            Icon(Icons.inventory_2_outlined, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: AppConstants.spacingMd),
            Text('No products', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppConstants.spacingXs),
            Text(
              'Add products with the button below to start building inventory.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: AppConstants.spacingSm),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
