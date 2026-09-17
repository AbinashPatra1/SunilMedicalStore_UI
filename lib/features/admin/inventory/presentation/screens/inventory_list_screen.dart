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

  /// Opens the scanner, then either edits the matching product (by
  /// [Product.barcode], against the already-loaded list — same client-side
  /// matching pattern as type/search filtering) or opens Add with the
  /// scanned code pre-filled if nothing matches.
  Future<void> _scanBarcode() async {
    final code = await context.push<String>(AppRoutes.adminInventoryScan);
    if (code == null || !mounted) return;
    final products = ref.read(adminInventoryListProvider).value ?? const [];
    Product? match;
    for (final p in products) {
      if (p.barcode == code) {
        match = p;
        break;
      }
    }
    if (!mounted) return;
    if (match != null) {
      context.push('${AppRoutes.adminInventoryEdit}/${match.id}');
    } else {
      context.push(AppRoutes.adminInventoryAdd, extra: code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filters = ref.watch(adminInventoryFiltersProvider);
    final productsAsync = ref.watch(adminInventoryListProvider);

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
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.spacingLg,
              AppConstants.spacingSm,
              AppConstants.spacingLg,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.upload_file_outlined,
                    label: 'Excel Import',
                    cardColor: const Color(0xFFD7F2E3),
                    badgeColor: const Color(0xFF1F9D55),
                    onTap: () => context.push(AppRoutes.adminInventoryImport),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingMd),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.qr_code_scanner_outlined,
                    label: 'Barcode Scanner',
                    cardColor: const Color(0xFFE3E4FB),
                    badgeColor: const Color(0xFF5B6DF2),
                    onTap: _scanBarcode,
                  ),
                ),
              ],
            ),
          ),
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

/// Colorful icon+label tile used for the "Excel Import"/"Barcode Scanner"
/// row above the category filters — fixed, theme-independent colors (same
/// reasoning as `CategoryIllustration`'s palette) so they stay vivid in
/// both light and dark mode.
class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.cardColor,
    required this.badgeColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color cardColor;
  final Color badgeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingSm,
          vertical: AppConstants.spacingMd,
        ),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: badgeColor,
              child: Icon(icon, size: 16, color: Colors.white),
            ),
            const SizedBox(width: AppConstants.spacingSm),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: badgeColor,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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
