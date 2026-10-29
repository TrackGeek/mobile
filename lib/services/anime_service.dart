import '../models/anime_detail.dart';
import '../models/api_exception.dart';
import '../models/paginated_page.dart';
import 'api_client.dart';

class AnimeService {
  const AnimeService(this._api);

  final ApiClient _api;

  Future<AnimeDetail> detail(
    String malId, {
    String language = 'en-US',
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'anime/detail/$malId',
      language: language,
      cancelWhen: cancelWhen,
    );
    final anime = res.json?['anime'];
    if (anime is! Map<String, dynamic>) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    try {
      return AnimeDetail.fromJson(anime);
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  Future<PaginatedPage<AnimeEpisode>> episodes(
    String malId, {
    int page = 1,
    int itemsPerPage = 24,
    String language = 'en-US',
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'anime/detail/$malId/episode',
      query: {'page': '$page', 'itemsPerPage': '$itemsPerPage'},
      language: language,
      cancelWhen: cancelWhen,
    );
    try {
      return PaginatedPage.fromJson(
        res.json?['episodes'] as Map<String, dynamic>,
        AnimeEpisode.fromJson,
      );
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    } on FormatException {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  Future<List<AnimeRelation>> relations(
    String malId, {
    String language = 'en-US',
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'anime/detail/$malId/relation',
      language: language,
      cancelWhen: cancelWhen,
    );
    final list = res.json?['relations'] ?? res.list;
    if (list is! List) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    try {
      return [
        for (final item in list)
          if (item is Map<String, dynamic>) AnimeRelation.fromJson(item),
      ];
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  Future<void> refresh(String malId) =>
      _api.requestJson('POST', 'anime/refresh', body: {'malId': malId});

  Future<AnimeProgress?> progress(
    String userId,
    String animeId, {
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'anime/progress',
      query: {'userId': userId, 'animeId': animeId},
      cancelWhen: cancelWhen,
    );
    final items = res.json?['animeProgresses'];
    final list = items is Map<String, dynamic> ? items['items'] : items;
    if (list is! List) return null;
    for (final item in list) {
      if (item is Map<String, dynamic>) return AnimeProgress.fromJson(item);
    }
    return null;
  }

  Future<void> saveProgress(
    String animeId, {
    required String status,
    int? watchCount,
    String? startedAt,
    String? completedAt,
  }) => _api.requestJson(
    'POST',
    'anime/progress',
    body: {
      'animeId': animeId,
      'status': status,
      'watchCount': ?watchCount,
      'startedAt': ?startedAt,
      'completedAt': ?completedAt,
    },
  );

  Future<void> deleteProgress(String animeProgressId) =>
      _api.requestJson('DELETE', 'anime/progress/$animeProgressId');

  Future<List<AnimeEpisodeWatch>> episodeWatch(
    String userId,
    String animeId, {
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'anime/episode/watch',
      query: {'userId': userId, 'animeId': animeId},
      cancelWhen: cancelWhen,
    );
    final items = res.json?['animeEpisodeWatch'];
    final list = items is Map<String, dynamic> ? items['items'] : items;
    if (list is! List) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    try {
      return [
        for (final item in list)
          if (item is Map<String, dynamic>) AnimeEpisodeWatch.fromJson(item),
      ];
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  Future<void> watchEpisodes(String animeId, List<int> episodes) =>
      _api.requestJson(
        'POST',
        'anime/episode/watch',
        body: {
          'animeId': animeId,
          'episodes': [
            for (final episode in episodes)
              {'episode': episode, 'status': 'Completed'},
          ],
        },
      );

  Future<void> unwatchEpisode(String animeId, int episode) => _api.requestJson(
    'DELETE',
    'anime/episode/watch',
    body: {'animeId': animeId, 'episode': episode},
  );

  Future<void> unwatchAll(String animeId) => _api.requestJson(
    'DELETE',
    'anime/episode/watch/all',
    body: {'animeId': animeId},
  );
}
