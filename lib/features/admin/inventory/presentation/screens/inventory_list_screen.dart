import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/routes/app_routes.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/admin/inventory/presentation/providers/inventory_providers.dart';
import 'package:sunil_medical_store/features/admin/inventory/presentation/widgets/inventory_item_tile.dart';
import 'package:sunil_medical_store/features/admin/presentation/widgets/admin_sign_out_button.dart';
import 'package:sunil_medical_store/features/dashboard/presentation/providers/dashboard_providers.dart';

/// Admin > Inventory: lists all products (in and out of stock), filterable by
/// category and by in-stock-only. Tapping a row edits; the FAB adds a new
/// product.
class InventoryListScreen extends ConsumerStatefulWidget {
  const InventoryListScreen({super.key});

  @override
  ConsumerState<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends ConsumerState<InventoryListScreen> {
  String _category = '';
  bool _inStockOnly = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(homeCategoriesProvider);
    final productsAsync = ref.watch(adminInventoryListProvider(_category));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: const [AdminSignOutButton()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.adminInventoryAdd),
        icon: const Icon(Icons.add),
        label: const Text('Add product'),
      ),
      body: Column(
        children: [
          // Category filter chips.
          categoriesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (categories) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingSm),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingLg),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _category.isEmpty,
                      onSelected: (_) => setState(() => _category = ''),
                    ),
                    for (final c in categories) ...[
                      const SizedBox(width: AppConstants.spacingSm),
                      ChoiceChip(
                        label: Text(c.label),
                        selected: _category == c.label,
                        onSelected: (_) => setState(() => _category = c.label),
                      ),
                    ],
                  ],
                ),
              ),
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
                onRetry: () => ref.invalidate(adminInventoryListProvider(_category)),
              ),
              data: (products) {
                final visible = _inStockOnly
                    ? products.where((p) => p.stock > 0).toList()
                    : products;
                if (visible.isEmpty) {
                  return const _EmptyView();
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(adminInventoryListProvider(_category)),
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
