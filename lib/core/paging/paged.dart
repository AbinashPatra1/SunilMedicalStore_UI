import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';

/// Page size for the customer's infinite-scroll lists.
const kPageSize = 20;

/// Page size for the admin's numbered-page lists.
const kAdminPageSize = 15;

/// One fetched page. [total] is the size of the whole result set when the
/// backend reports it (`X-Total-Count` header), else `null`.
class PageResult<T> {
  const PageResult({required this.items, required this.hasMore, this.total});

  final List<T> items;
  final bool hasMore;
  final int? total;
}

/// `GET`s one page of a list endpoint — `?page=&pageSize=` on top of [query]
/// — and parses it. Paging is opt-in and backwards-compatible with a plain
/// array response (`docs/API_ENDPOINTS.md` §Pagination):
/// * the total comes from the optional `X-Total-Count` header;
/// * a backend that ignores the params and returns more than [pageSize]
///   rows is treated as having sent the complete list (no further pages).
Future<PageResult<T>> fetchPageOf<T>(
  Dio dio,
  String path, {
  Map<String, dynamic>? query,
  required int page,
  required int pageSize,
  required T Function(Map<String, dynamic>) fromJson,
}) async {
  try {
    final response = await dio.get<List<dynamic>>(
      path,
      queryParameters: {...?query, 'page': page, 'pageSize': pageSize},
    );
    final all = (response.data ?? const []).cast<Map<String, dynamic>>().map(fromJson).toList();
    final total = int.tryParse(response.headers.value('x-total-count') ?? '');
    if (all.length > pageSize) {
      // No total: the count says nothing about page numbers when paging was
      // ignored, and a null total keeps the admin pager hidden.
      return PageResult(items: page == 1 ? all : const [], hasMore: false);
    }
    final hasMore = total != null ? page * pageSize < total : all.length == pageSize;
    return PageResult(items: all, hasMore: hasMore, total: total);
  } on DioException catch (e) {
    throw ApiException.fromDioException(e);
  }
}

/// What a paged list screen renders.
///
/// Infinite lists (customer) keep appending: [items] is everything loaded
/// so far and [page] the last page fetched. Numbered lists (admin) hold just
/// the current page in [items].
class PagedState<T> {
  const PagedState({
    required this.items,
    required this.page,
    required this.hasMore,
    this.total,
    this.pageSize = kPageSize,
    this.busy = false,
    this.loadError,
  });

  final List<T> items;
  final int page;
  final bool hasMore;
  final int? total;
  final int pageSize;

  /// A further page (or a page switch) is in flight.
  final bool busy;

  /// The last load-more / page switch failed.
  final Object? loadError;

  /// Number of pages, when the backend reported a total.
  int? get pageCount => total == null ? null : math.max(1, (total! / pageSize).ceil());

  PagedState<T> copyWith({
    List<T>? items,
    int? page,
    bool? hasMore,
    int? total,
    bool? busy,
    Object? loadError,
    bool clearError = false,
  }) => PagedState(
    items: items ?? this.items,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    total: total ?? this.total,
    pageSize: pageSize,
    busy: busy ?? this.busy,
    loadError: clearError ? null : (loadError ?? this.loadError),
  );
}

/// Base for a paged list provider's notifier. A subclass supplies [fetch]
/// (one page) and [keyOf] (a stable id per item) and, in its `build`, reads
/// any filters it depends on with `ref.watch` and returns [loadFirst] — so a
/// filter change rebuilds the list from page 1.
abstract class PagedNotifier<T> extends AsyncNotifier<PagedState<T>> {
  int get pageSize => kPageSize;

  Future<PageResult<T>> fetch(int page);

  Object keyOf(T item);

  int _generation = 0;

  Future<PagedState<T>> loadFirst() async {
    final generation = ++_generation;
    final r = await fetch(1);
    if (generation != _generation) return state.value ?? _empty;
    return PagedState(items: r.items, page: 1, hasMore: r.hasMore, total: r.total, pageSize: pageSize);
  }

  PagedState<T> get _empty => PagedState(items: const [], page: 1, hasMore: false, pageSize: pageSize);

  /// Infinite scroll: appends the next page.
  Future<void> loadMore() async {
    final s = state.value;
    if (s == null || s.busy || !s.hasMore) return;
    final generation = _generation;
    state = AsyncData(s.copyWith(busy: true, clearError: true));
    try {
      final r = await fetch(s.page + 1);
      if (generation != _generation) return;
      // A backend that ignores paging would resend the same rows — only
      // keep what's new, and stop when nothing is.
      final known = s.items.map(keyOf).toSet();
      final fresh = r.items.where((e) => !known.contains(keyOf(e))).toList();
      state = AsyncData(
        s.copyWith(
          items: [...s.items, ...fresh],
          page: s.page + 1,
          hasMore: fresh.isNotEmpty && r.hasMore,
          total: r.total,
          busy: false,
        ),
      );
    } catch (e) {
      if (generation != _generation) return;
      state = AsyncData(s.copyWith(busy: false, loadError: e));
    }
  }

  /// Numbered pages: replaces the items with page [page].
  Future<void> goToPage(int page) async {
    final s = state.value;
    if (s == null || s.busy || page == s.page || page < 1) return;
    final generation = _generation;
    state = AsyncData(s.copyWith(busy: true, clearError: true));
    try {
      final r = await fetch(page);
      if (generation != _generation) return;
      state = AsyncData(
        PagedState(items: r.items, page: page, hasMore: r.hasMore, total: r.total ?? s.total, pageSize: pageSize),
      );
    } catch (e) {
      if (generation != _generation) return;
      state = AsyncData(s.copyWith(busy: false, loadError: e));
    }
  }
}
