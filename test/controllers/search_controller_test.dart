import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackgeek/controllers/search_controller.dart';
import 'package:trackgeek/models/api_exception.dart';
import 'package:trackgeek/models/media_type.dart';
import 'package:trackgeek/models/search_item.dart';
import 'package:trackgeek/services/search_service.dart';

import 'fake_search_gateway.dart';

void main() {
  test('search loads first page', () async {
    final gateway = FakeSearchGateway();
    final controller = SearchController(
      gateway,
      initialKind: const MediaSearchKind(MediaType.anime),
    );
    await controller.search('naruto');
    expect(controller.results.length, 2);
    expect(controller.total, 2);
    expect(controller.hasNextPage, isFalse);
    expect(controller.isLoading, isFalse);
    expect(gateway.lastQuery, 'naruto');
  });

  test('debounce delays search', () {
    fakeAsync((async) {
      final gateway = FakeSearchGateway();
      final controller = SearchController(
        gateway,
        initialKind: const MediaSearchKind(MediaType.movie),
      );
      controller.onQueryChanged('dune');
      async.elapse(const Duration(milliseconds: 599));
      expect(gateway.calls, 0);
      async.elapse(const Duration(milliseconds: 2));
      expect(gateway.calls, 1);
    });
  });

  test('rapid typing triggers one search', () {
    fakeAsync((async) {
      final gateway = FakeSearchGateway();
      final controller = SearchController(
        gateway,
        initialKind: const MediaSearchKind(MediaType.movie),
      );
      controller.onQueryChanged('d');
      async.elapse(const Duration(milliseconds: 300));
      controller.onQueryChanged('du');
      async.elapse(const Duration(milliseconds: 300));
      controller.onQueryChanged('dun');
      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();
      expect(gateway.calls, 1);
      expect(gateway.lastQuery, 'dun');
    });
  });

  test('setKind searches again with new kind', () async {
    final gateway = FakeSearchGateway();
    final controller = SearchController(
      gateway,
      initialKind: const MediaSearchKind(MediaType.movie),
    );
    await controller.search('x');
    await controller.setKind(const UserSearchKind());
    expect(gateway.lastKind, isA<UserSearchKind>());
    expect(controller.results.first.target, SearchTarget.user);
  });

  test('setKind clears query and filters like the web type switch', () async {
    final gateway = FakeSearchGateway();
    final controller = SearchController(
      gateway,
      initialKind: const MediaSearchKind(MediaType.movie),
    );
    await controller.search('dune');
    await controller.setFilters(const {'year': '2021', 'orderBy': 'score'});
    await controller.setKind(const MediaSearchKind(MediaType.anime));
    expect(controller.query, isEmpty);
    expect(controller.filters, isEmpty);
    expect(gateway.lastQuery, isEmpty);
    expect(gateway.lastFilters, isEmpty);
  });

  test('media results deduplicate by provider id across pages', () async {
    final gateway = FakeSearchGateway(
      pages: 2,
      fixedItems: [
        {'malId': 1, 'title': 'A', 'isAdult': false},
        {'malId': 2, 'title': 'B', 'isAdult': false},
        {'malId': 1, 'title': 'A dup', 'isAdult': false},
        {'anilistId': 5, 'title': 'Ani only', 'isAdult': false},
      ],
    );
    final controller = SearchController(
      gateway,
      initialKind: const MediaSearchKind(MediaType.anime),
    );
    await controller.search('x');
    expect(controller.results.map((i) => i.title), ['A', 'B', 'Ani only']);
    await controller.loadNextPage();
    expect(controller.results.map((i) => i.title), [
      'A',
      'B',
      'Ani only',
      'Ani only',
    ]);
  });

  test('non-media kinds keep duplicates', () async {
    final gateway = FakeSearchGateway(
      fixedItems: [
        {'id': 'u1', 'username': 'ana', 'name': 'Ana'},
        {'id': 'u1', 'username': 'ana', 'name': 'Ana'},
      ],
    );
    final controller = SearchController(
      gateway,
      initialKind: const UserSearchKind(),
    );
    await controller.search('x');
    expect(controller.results.length, 2);
  });

  test('loadNextPage appends results', () async {
    final gateway = FakeSearchGateway(pages: 2);
    final controller = SearchController(
      gateway,
      initialKind: const MediaSearchKind(MediaType.movie),
    );
    await controller.search('x');
    expect(controller.hasNextPage, isTrue);
    await controller.loadNextPage();
    expect(controller.results.length, 4);
    expect(controller.hasNextPage, isFalse);
    expect(gateway.lastPage, 2);
  });

  test('error is exposed and keeps empty results', () async {
    final gateway = FakeSearchGateway(
      error: const ApiException(ApiFailure.network),
    );
    final controller = SearchController(
      gateway,
      initialKind: const MediaSearchKind(MediaType.movie),
    );
    await controller.search('x');
    expect(controller.error?.failure, ApiFailure.network);
    expect(controller.results, isEmpty);
  });

  test('pagination failure keeps previous results', () async {
    final gateway = FakeSearchGateway(pages: 2);
    final controller = SearchController(
      gateway,
      initialKind: const MediaSearchKind(MediaType.movie),
    );
    await controller.search('x');
    final first = controller.results;
    gateway.error = const ApiException(ApiFailure.network);
    await controller.loadNextPage();
    expect(controller.results, first);
    expect(controller.isLoadingMore, isFalse);
  });
}
