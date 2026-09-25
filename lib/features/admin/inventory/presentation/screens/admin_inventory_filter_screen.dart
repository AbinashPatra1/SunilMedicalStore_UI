import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/admin/inventory/domain/inventory_filters.dart';
import 'package:sunil_medical_store/features/admin/inventory/presentation/providers/inventory_filters_provider.dart';
import 'package:sunil_medical_store/features/medicines/domain/product_category.dart';
import 'package:sunil_medical_store/features/medicines/domain/product_type.dart';

/// Dedicated full-screen filter for Admin Inventory — product category,
/// product type, and a text search across name/category/type/composition/
/// ingredients (the last four matched client-side, since the backend only
/// supports filtering by category — see `adminInventoryListProvider`).
class AdminInventoryFilterScreen extends ConsumerStatefulWidget {
  const AdminInventoryFilterScreen({super.key});

  @override
  ConsumerState<AdminInventoryFilterScreen> createState() => _AdminInventoryFilterScreenState();
}

class _AdminInventoryFilterScreenState extends ConsumerState<AdminInventoryFilterScreen> {
  late ProductCategory? _category;
  late ProductType? _type;
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    final current = ref.read(adminInventoryFiltersProvider);
    _category = current.category;
    _type = current.type;
    _search = TextEditingController(text: current.search);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _apply() {
    final inStockOnly = ref.read(adminInventoryFiltersProvider).inStockOnly;
    ref.read(adminInventoryFiltersProvider.notifier).apply(
      AdminInventoryFilters(category: _category, type: _type, search: _search.text.trim(), inStockOnly: inStockOnly),
    );
    context.pop();
  }

  void _reset() {
    setState(() {
      _category = null;
      _type = null;
      _search.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Filter Inventory'),
        actions: [
          TextButton(onPressed: _reset, child: const Text('Reset')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        children: [
          TextField(
            controller: _search,
            decoration: const InputDecoration(
              labelText: 'Search',
              hintText: 'Name, category, type, composition or ingredient',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: AppConstants.spacingXl),
          Text('Category', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppConstants.spacingSm),
          Wrap(
            spacing: AppConstants.spacingSm,
            runSpacing: AppConstants.spacingSm,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _category == null,
                onSelected: (_) => setState(() => _category = null),
              ),
              for (final c in ProductCategory.values)
                ChoiceChip(
                  label: Text(c.label),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _category = c),
                ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingXl),
          Text('Product type', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppConstants.spacingSm),
          Wrap(
            spacing: AppConstants.spacingSm,
            runSpacing: AppConstants.spacingSm,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _type == null,
                onSelected: (_) => setState(() => _type = null),
              ),
              for (final t in ProductType.values)
                ChoiceChip(
                  label: Text(t.label),
                  selected: _type == t,
                  onSelected: (_) => setState(() => _type = t),
                ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          child: FilledButton(
            onPressed: _apply,
            child: const Text('Apply filters'),
          ),
        ),
      ),
    );
  }
}
