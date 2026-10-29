import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/api_exception.dart';
import '../models/media_type.dart';
import '../models/paginated_page.dart';
import '../models/progress_item.dart';
import 'api_client.dart';
import 'widget_sync.dart';

class ProgressResult {
  const ProgressResult({required this.page, required this.statusCounts});

  final PaginatedPage<ProgressItem> page;
  final Map<String, int> statusCounts;
}

class ProgressFilterOptions {
  const ProgressFilterOptions({
    this.selectedPlatforms = const [],
    this.availablePlatforms = const [],
    this.genres = const [],
    this.years = const [],
    this.releaseStates = const [],
  });

  final List<({String slug, String name})> selectedPlatforms;
  final List<({String slug, String name})> availablePlatforms;
  final List<String> genres;
  final List<int> years;
  final List<String> releaseStates;
}

class ProgressService extends ChangeNotifier {
  ProgressService(this._api);

  final ApiClient _api;
  final Set<String> _pending = {};

  void refresh() => notifyListeners();

  Future<void> increment(ProgressItem item) async {
    final key = '${item.type.name}:${item.mediaId}';
    if (!item.canIncrement || !_pending.add(key)) return;
    try {
      final episodes =
          item.type == MediaType.anime || item.type == MediaType.tv;
      await _api.requestJson(
        'POST',
        '${item.type.slug}/${episodes ? 'episode/watch' : 'progress'}',
        body: episodes
            ? {
                item.type == MediaType.anime ? 'animeId' : 'tvShowId':
                    item.mediaId,
                'episodes': [
                  {...item.nextEpisode!, 'status': 'Completed'},
                ],
              }
            : {
                '${item.type.slug}Id': item.mediaId,
                'status': item.status,
                'chaptersRead': item.current! + 1,
              },
      );
      notifyListeners();
      unawaited(WidgetSync.refresh());
    } finally {
      _pending.remove(key);
    }
  }

  static const _envelope = {
    MediaType.anime: 'animeProgresses',
    MediaType.manga: 'mangaProgresses',
    MediaType.tv: 'tvShowProgresses',
    MediaType.movie: 'movieProgresses',
    MediaType.game: 'gameProgresses',
    MediaType.book: 'bookProgresses',
  };

  Future<List<ProgressItem>> activeProgress(
    MediaType type, {
    required String userId,
    required List<String> statuses,
    int limit = 6,
    String language = 'en-US',
  }) async {
    final pages = await Future.wait(
      statuses.map(
        (status) => progress(
          type,
          userId: userId,
          status: status,
          itemsPerPage: limit,
          language: language,
        ),
      ),
    );
    final items = [for (final page in pages) ...page.items]
      ..sort(
        (a, b) =>
            (b.updatedAt ?? DateTime(0)).compareTo(a.updatedAt ?? DateTime(0)),
      );
    return items.take(limit).toList();
  }

  Future<ProgressResult> userProgress(
    MediaType type, {
    required String userId,
    String? status,
    String sortBy = 'addedAt',
    String sortOrder = 'desc',
    List<String> completion = const [],
    List<String> selectedPlatforms = const [],
    List<String> availablePlatforms = const [],
    List<String> genres = const [],
    String year = '',
    bool? released,
    List<String> releaseStates = const [],
    String search = '',
    int page = 1,
    int itemsPerPage = 20,
    String language = 'en-US',
    Future<void>? cancelWhen,
  }) async {
    if (userId.isEmpty) throw ArgumentError.value(userId, 'userId');
    final trimmedYear = year.trim();
    final trimmedSearch = search.trim();
    final json = await _api.requestJson(
      'GET',
      '${type.slug}/progress/',
      query: {
        'userId': userId,
        'status': ?status,
        if (completion.isNotEmpty) 'completion': completion.join(','),
        if (selectedPlatforms.isNotEmpty)
          'selectedPlatforms': selectedPlatforms.join(','),
        if (availablePlatforms.isNotEmpty)
          'availablePlatforms': availablePlatforms.join(','),
        if (genres.isNotEmpty) 'genres': genres.join(','),
        if (RegExp(r'^\d{4}$').hasMatch(trimmedYear)) 'year': trimmedYear,
        if (released != null) 'released': '$released',
        if (releaseStates.isNotEmpty) 'releaseStates': releaseStates.join(','),
        if (trimmedSearch.isNotEmpty) 'search': trimmedSearch,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
        'page': '$page',
        'itemsPerPage': '$itemsPerPage',
      },
      language: language,
      cancelWhen: cancelWhen,
    );
    try {
      final body = json.json!;
      final counts = <String, int>{};
      final rawCounts = body['statusCounts'];
      if (rawCounts is Map<String, dynamic>) {
        for (final entry in rawCounts.entries) {
          counts[entry.key] = (entry.value as num?)?.toInt() ?? 0;
        }
      }
      return ProgressResult(
        page: PaginatedPage.fromJson(
          body[_envelope[type]] as Map<String, dynamic>,
          (item) => ProgressItem.fromJson(type, item),
        ),
        statusCounts: counts,
      );
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    } on FormatException {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  Future<ProgressFilterOptions> progressFilters(
    MediaType type, {
    required String userId,
    String language = 'en-US',
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      '${type.slug}/progress/filters',
      query: {'userId': userId},
      language: language,
      cancelWhen: cancelWhen,
    );
    final filters = res.json?['filters'];
    if (filters is! Map<String, dynamic>) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    List<String> strings(String key) => [
      for (final item in filters[key] as List? ?? const []) '$item',
    ];
    List<({String slug, String name})> platforms(String key) => [
      for (final item in filters[key] as List? ?? const [])
        if (item is Map<String, dynamic>)
          (slug: '${item['slug']}', name: '${item['name'] ?? item['slug']}'),
    ];
    return ProgressFilterOptions(
      selectedPlatforms: platforms('selectedPlatforms'),
      availablePlatforms: platforms('availablePlatforms'),
      genres: strings('genres'),
      years: [
        for (final item in filters['years'] as List? ?? const [])
          (item as num).toInt(),
      ],
      releaseStates: strings('releaseStates'),
    );
  }

  Future<PaginatedPage<ProgressItem>> progress(
    MediaType type, {
    required String userId,
    String? status,
    int page = 1,
    int itemsPerPage = 20,
    String language = 'en-US',
    Future<void>? cancelWhen,
  }) async {
    if (userId.isEmpty) throw ArgumentError.value(userId, 'userId');
    final json = await _api.getJson(
      '${type.slug}/progress',
      query: {
        'userId': userId,
        'status': ?status,
        'sortBy': 'updatedAt',
        'sortOrder': 'desc',
        'page': '$page',
        'itemsPerPage': '$itemsPerPage',
      },
      language: language,
      cancelWhen: cancelWhen,
    );
    try {
      return PaginatedPage.fromJson(
        json[_envelope[type]] as Map<String, dynamic>,
        (item) => ProgressItem.fromJson(type, item),
      );
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    } on FormatException {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }
}
