import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sunil_medical_store/core/paging/paged.dart';
import 'package:sunil_medical_store/core/paging/paged_widgets.dart';

/// Serves `rows` items, honouring `page`/`pageSize` unless [ignorePaging].
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.rows, {this.ignorePaging = false, this.reportTotal = true});

  final int rows;
  final bool ignorePaging;
  final bool reportTotal;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final page = options.queryParameters['page'] as int;
    final size = options.queryParameters['pageSize'] as int;
    final all = List.generate(rows, (i) => {'id': 'r$i'});
    final slice = ignorePaging ? all : all.skip((page - 1) * size).take(size).toList();
    return ResponseBody.fromString(
      jsonEncode(slice),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
        if (reportTotal && !ignorePaging) 'x-total-count': ['$rows'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dio(_FakeAdapter a) => Dio()..httpClientAdapter = a;

Future<PageResult<String>> _page(Dio dio, int page, {int size = 10}) => fetchPageOf(
  dio,
  '/x',
  page: page,
  pageSize: size,
  fromJson: (j) => j['id'] as String,
);

class _Notifier extends PagedNotifier<String> {
  _Notifier(this.dio);

  final Dio dio;

  @override
  int get pageSize => 10;

  @override
  Future<PagedState<String>> build() => loadFirst();

  @override
  Future<PageResult<String>> fetch(int page) => _page(dio, page);

  @override
  Object keyOf(String item) => item;
}

AsyncNotifierProvider<_Notifier, PagedState<String>> _provider(Dio dio) =>
    AsyncNotifierProvider<_Notifier, PagedState<String>>(() => _Notifier(dio));

void main() {
  group('fetchPageOf', () {
    test('uses the total header to know whether more pages exist', () async {
      final dio = _dio(_FakeAdapter(25));
      final p1 = await _page(dio, 1);
      expect(p1.items.length, 10);
      expect(p1.total, 25);
      expect(p1.hasMore, isTrue);
      final p3 = await _page(dio, 3);
      expect(p3.items.length, 5);
      expect(p3.hasMore, isFalse);
    });

    test('without a total, a full page means there may be more', () async {
      final dio = _dio(_FakeAdapter(20, reportTotal: false));
      expect((await _page(dio, 1)).hasMore, isTrue);
      expect((await _page(dio, 2)).hasMore, isTrue); // full page, can't know
      expect((await _page(dio, 3)).items, isEmpty);
    });

    test('a backend that ignores paging is treated as the complete list', () async {
      final dio = _dio(_FakeAdapter(37, ignorePaging: true));
      final p1 = await _page(dio, 1);
      expect(p1.items.length, 37);
      expect(p1.hasMore, isFalse);
      expect(p1.total, isNull); // so the admin pager stays hidden
    });
  });

  group('PagedNotifier', () {
    test('infinite scroll appends pages until the end', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = _provider(_dio(_FakeAdapter(25)));

      var s = await container.read(provider.future);
      expect(s.items.length, 10);
      await container.read(provider.notifier).loadMore();
      await container.read(provider.notifier).loadMore();
      s = container.read(provider).requireValue;
      expect(s.items.length, 25);
      expect(s.hasMore, isFalse);
      expect(s.items.toSet().length, 25);
      // Nothing more to load: a further call is a no-op.
      await container.read(provider.notifier).loadMore();
      expect(container.read(provider).requireValue.items.length, 25);
    });

    test('never duplicates rows when the backend resends the same page', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // Exactly one page worth of rows, paging ignored: page 2 == page 1.
      final adapter = _FakeAdapter(10, ignorePaging: true);
      final provider = _provider(_dio(adapter));

      final first = await container.read(provider.future);
      expect(first.items.length, 10);
      expect(first.hasMore, isTrue); // looks like a full page
      await container.read(provider.notifier).loadMore();
      final s = container.read(provider).requireValue;
      expect(s.items.length, 10);
      expect(s.hasMore, isFalse);
    });

    test('numbered pages replace the items and report the page count', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provider = _provider(_dio(_FakeAdapter(25)));

      await container.read(provider.future);
      expect(container.read(provider).requireValue.pageCount, 3);
      await container.read(provider.notifier).goToPage(3);
      final s = container.read(provider).requireValue;
      expect(s.page, 3);
      expect(s.items, ['r20', 'r21', 'r22', 'r23', 'r24']);
      await container.read(provider.notifier).goToPage(1);
      expect(container.read(provider).requireValue.items.first, 'r0');
    });
  });

  group('widgets', () {
    testWidgets('InfiniteListView asks for more when the first page is short', (tester) async {
      var loads = 0;
      final state = PagedState<String>(items: List.generate(3, (i) => 'item $i'), page: 1, hasMore: true);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InfiniteListView<String>(
              state: state,
              onLoadMore: () => loads++,
              itemBuilder: (context, item) => Text(item),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(loads, greaterThan(0));
      expect(find.text('item 0'), findsOneWidget);
    });

    testWidgets('InfiniteListView does not load when there is nothing more', (tester) async {
      var loads = 0;
      final state = PagedState<String>(items: const ['a'], page: 1, hasMore: false);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InfiniteListView<String>(
              state: state,
              onLoadMore: () => loads++,
              itemBuilder: (context, item) => Text(item),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(loads, 0);
    });

    testWidgets('PageNumberBar selects pages and hides for a single page', (tester) async {
      int? selected;
      Future<void> pump(PagedState<Object?> s) => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PageNumberBar(state: s, onSelect: (p) => selected = p)),
        ),
      );

      await pump(const PagedState<Object?>(items: [], page: 2, hasMore: true, total: 100, pageSize: 15));
      expect(find.text('1'), findsOneWidget);
      expect(find.text('7'), findsNothing); // 100 / 15 -> 7 pages, window of 5 around page 2
      await tester.tap(find.text('3'));
      expect(selected, 3);
      await tester.tap(find.byTooltip('Next page'));
      expect(selected, 3);

      await pump(const PagedState<Object?>(items: [], page: 1, hasMore: false, total: 5, pageSize: 15));
      expect(find.byType(IconButton), findsNothing);
    });
  });
}
