import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/routes/app_routes.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/features/cart/presentation/providers/cart_providers.dart';
import 'package:sunil_medical_store/features/medicines/presentation/providers/medicine_providers.dart';
import 'package:sunil_medical_store/features/medicines/presentation/widgets/product_card.dart';

/// Dashboard search: free-text lookup across the medicine/product catalog,
/// reached by tapping the search bar on the Pharmacy tab.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String value) => setState(() => _query = value.trim());

  void _clear() {
    _controller.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: _submit,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Search medicines, health products…',
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(icon: const Icon(Icons.clear), onPressed: _clear),
          ),
        ),
      ),
      body: _query.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingXl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search, size: 56, color: theme.colorScheme.primary),
                    const SizedBox(height: AppConstants.spacingMd),
                    Text(
                      'Search for medicines, health products, and more.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : _Results(query: _query),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(searchProductsProvider(query));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error is ApiException ? error.message : 'Could not load results.'),
            const SizedBox(height: AppConstants.spacingSm),
            TextButton(
              onPressed: () => ref.invalidate(searchProductsProvider(query)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (products) {
        if (products.isEmpty) {
          return Center(
            child: Text(
              'No results for "$query".',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          itemCount: products.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppConstants.spacingMd),
          itemBuilder: (context, index) {
            final product = products[index];
            return ProductCard(
              product: product,
              onTap: () => context.push('${AppRoutes.medicineDetail}/${product.id}'),
              onAdd: () {
                ref.read(cartProvider.notifier).addProduct(product);
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text('${product.name} added to cart')));
              },
            );
          },
        );
      },
    );
  }
}
