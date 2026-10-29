import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/api_exception.dart';
import '../models/paginated_page.dart';
import '../models/search_item.dart';
import '../services/search_service.dart';

class SearchController extends ChangeNotifier {
  SearchController(
    this._service, {
    required SearchKind initialKind,
    this.debounce = const Duration(milliseconds: 600),
    Map<String, String> initialFilters = const {},
  }) : _kind = initialKind,
       _filters = initialFilters;

  final SearchGateway _service;
  final Duration debounce;

  Timer? _debounce;
  Completer<void>? _cancel;
  int _generation = 0;

  late SearchKind _kind;
  String _query = '';
  int _page = 0;
  List<SearchItem> _results = const [];
  int? _total;
  bool _hasNextPage = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  ApiException? _error;
  bool _searched = false;
  Map<String, String> _filters = const {};
  final Set<String> _seen = {};

  SearchKind get kind => _kind;
  String get query => _query;
  List<SearchItem> get results => _results;
  int? get total => _total;
  bool get hasNextPage => _hasNextPage;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  ApiException? get error => _error;
  Map<String, String> get filters => _filters;
  bool get searched => _searched;

  void onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(debounce, () {
      if (value != _query || !_searched) search(value);
    });
  }

  Future<void> setFilters(Map<String, String> filters) async {
    _filters = Map.unmodifiable(filters);
    await search();
  }

  Future<void> setFilter(String key, String? value) {
    final next = {..._filters};
    if (value == null || value.isEmpty) {
      next.remove(key);
    } else {
      next[key] = value;
    }
    return setFilters(next);
  }

  Future<void> clearFilters() => setFilters(const {});

  Future<void> setKind(SearchKind kind) async {
    if (kind.path == _kind.path) return;
    _kind = kind;
    _query = '';
    _filters = const {};
    await search();
  }

  Future<void> search([String? query]) async {
    _debounce?.cancel();
    if (query != null) _query = query.trim();
    _searched = true;
    _page = 0;
    _results = const [];
    _total = null;
    _hasNextPage = false;
    _seen.clear();
    await _load(1);
  }

  Future<void> retry() => search();

  Future<void> loadNextPage() async {
    if (!_hasNextPage || _isLoading || _isLoadingMore) return;
    _isLoadingMore = true;
    notifyListeners();
    await _load(_page + 1, keepResults: true);
    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> _load(int page, {bool keepResults = false}) async {
    _cancel?.complete();
    final cancel = Completer<void>();
    _cancel = cancel;
    final generation = ++_generation;
    _isLoading = !keepResults;
    _error = null;
    notifyListeners();
    try {
      final result = await _service.search(
        _kind,
        query: _query,
        page: page,
        filters: _filters,
        cancelWhen: cancel.future,
      );
      if (generation != _generation) return;
      _apply(result, keepResults: keepResults);
    } on ApiException catch (e) {
      if (e.failure == ApiFailure.cancelled || generation != _generation) {
        return;
      }
      _error = e;
      _results = keepResults ? _results : const [];
    } finally {
      if (generation == _generation) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void _apply(PaginatedPage<SearchItem> page, {required bool keepResults}) {
    _page = page.inPage;
    final items = _kind is MediaSearchKind
        ? page.items
              .where((item) {
                final key = item.dedupKey;
                return key == null || _seen.add(key);
              })
              .toList(growable: false)
        : page.items;
    _results = keepResults
        ? List.unmodifiable([..._results, ...items])
        : List.unmodifiable(items);
    _total = page.total;
    _hasNextPage = page.hasNextPage;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cancel?.complete();
    super.dispose();
  }
}
