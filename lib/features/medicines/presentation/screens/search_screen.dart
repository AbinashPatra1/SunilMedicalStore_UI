import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sunil_medical_store/core/illustrations/search_empty_illustration.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/core/routes/app_routes.dart';
import 'package:sunil_medical_store/core/theme/app_constants.dart';
import 'package:sunil_medical_store/core/utils/week_range.dart';
import 'package:sunil_medical_store/features/appointments/presentation/providers/appointment_providers.dart';
import 'package:sunil_medical_store/features/appointments/presentation/utils/book_appointment.dart';
import 'package:sunil_medical_store/features/appointments/presentation/widgets/doctor_card.dart';
import 'package:sunil_medical_store/features/cart/presentation/providers/cart_providers.dart';
import 'package:sunil_medical_store/features/lab_tests/presentation/providers/lab_test_providers.dart';
import 'package:sunil_medical_store/features/lab_tests/presentation/widgets/lab_test_card.dart';
import 'package:sunil_medical_store/features/medicines/presentation/providers/medicine_providers.dart';
import 'package:sunil_medical_store/features/medicines/presentation/widgets/product_card.dart';
import 'package:sunil_medical_store/core/paging/paged_widgets.dart';

/// Minimum query length before a search actually fires — matches predictive
/// search across all three catalogs (Pharmacy/Pathology/Doctors).
const _kMinQueryLength = 3;

/// Debounce between the last keystroke and firing the search, so a fast
/// typist doesn't trigger a request per character.
const _kSearchDebounce = Duration(milliseconds: 300);

/// Dashboard search: free-text lookup across products, lab tests and
/// doctors, reached by tapping the search bar on the Pharmacy tab.
///
/// Live/predictive: once the query reaches [_kMinQueryLength] characters,
/// results for all three catalogs update automatically (debounced) as the
/// user keeps typing — no explicit submit needed. Below that length, a
/// prompt is shown instead of the tab bar.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_kSearchDebounce, () {
      if (mounted) setState(() => _query = value.trim());
    });
    // Clearing the field (or the clear button) should feel instant, not
    // wait out the debounce.
    if (value.trim().isEmpty && _query.isNotEmpty) {
      _debounce?.cancel();
      setState(() => _query = '');
    }
  }

  void _clear() {
    _controller.clear();
    _debounce?.cancel();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final showResults = _query.length >= _kMinQueryLength;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.only(right: AppConstants.spacingMd),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onChanged,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Search medicines, lab tests, doctors…',
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(icon: const Icon(Icons.clear), onPressed: _clear),
              ),
            ),
          ),
          bottom: showResults
              ? const TabBar(
                  tabs: [
                    Tab(text: 'Pharmacy'),
                    Tab(text: 'Pathology'),
                    Tab(text: 'Doctors'),
                  ],
                )
              : null,
        ),
        body: showResults
            ? TabBarView(
                children: [
                  _ProductResults(query: _query),
                  _LabTestResults(query: _query),
                  _DoctorResults(query: _query),
                ],
              )
            : _Prompt(
                query: _query,
                minLength: _kMinQueryLength,
              ),
      ),
    );
  }
}

class _Prompt extends StatelessWidget {
  const _Prompt({required this.query, required this.minLength});

  final String query;
  final int minLength;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = query.isEmpty
        ? 'Search for medicines, lab tests, and doctors.'
        : 'Keep typing… (at least $minLength characters)';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SearchEmptyIllustration(size: 96),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SearchEmptyIllustration(size: 96),
            const SizedBox(height: AppConstants.spacingMd),
            Text(
              'No results for "$query".',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorResults extends StatelessWidget {
  const _ErrorResults({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(error is ApiException ? (error as ApiException).message : 'Could not load results.'),
          const SizedBox(height: AppConstants.spacingSm),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _ProductResults extends ConsumerWidget {
  const _ProductResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(searchProductsProvider(query));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorResults(
        error: error,
        onRetry: () => ref.invalidate(searchProductsProvider(query)),
      ),
      data: (paged) {
        if (paged.items.isEmpty) return _EmptyResults(query: query);
        return InfiniteListView(
          state: paged,
          onLoadMore: () => ref.read(searchProductsProvider(query).notifier).loadMore(),
          itemBuilder: (context, product) {
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

class _LabTestResults extends ConsumerWidget {
  const _LabTestResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(searchLabTestsProvider(query));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorResults(
        error: error,
        onRetry: () => ref.invalidate(searchLabTestsProvider(query)),
      ),
      data: (paged) {
        if (paged.items.isEmpty) return _EmptyResults(query: query);
        return InfiniteListView(
          state: paged,
          onLoadMore: () => ref.read(searchLabTestsProvider(query).notifier).loadMore(),
          itemBuilder: (context, test) {
            return LabTestCard(
              test: test,
              onTap: () => context.push('${AppRoutes.labTests}/${test.id}'),
            );
          },
        );
      },
    );
  }
}

class _DoctorResults extends ConsumerWidget {
  const _DoctorResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(searchDoctorsProvider(query));
    final week = WeekRange.of(DateTime.now());

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorResults(
        error: error,
        onRetry: () => ref.invalidate(searchDoctorsProvider(query)),
      ),
      data: (paged) {
        if (paged.items.isEmpty) return _EmptyResults(query: query);
        return InfiniteListView(
          state: paged,
          onLoadMore: () => ref.read(searchDoctorsProvider(query).notifier).loadMore(),
          itemBuilder: (context, doctor) {
            return DoctorCard(
              doctor: doctor,
              week: week,
              onBook: () => bookAppointment(context, ref, doctor),
            );
          },
        );
      },
    );
  }
}
