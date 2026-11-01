import '../models/api_exception.dart';
import '../models/tv_detail.dart';
import 'api_client.dart';

class TvShowService {
  const TvShowService(this._api);

  final ApiClient _api;

  Future<TvShowDetail> detail(
    int tmdbId, {
    String? language,
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'tv/detail/$tmdbId',
      language: language,
      cancelWhen: cancelWhen,
    );
    final tvShow = res.json?['tvShow'];
    if (tvShow is! Map<String, dynamic>) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    try {
      return TvShowDetail.fromJson(tvShow);
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  Future<List<TvSeason>> seasons(
    int tmdbId, {
    String? language,
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'tv/detail/$tmdbId/season',
      language: language,
      cancelWhen: cancelWhen,
    );
    final seasons = res.json?['seasons'];
    if (seasons is! List) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    try {
      return [
        for (final s in seasons)
          if (s is Map<String, dynamic>) TvSeason.fromJson(s),
      ];
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  Future<List<TvSeasonEpisode>> seasonEpisodes(
    int tmdbId,
    int seasonNumber, {
    String? language,
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'tv/detail/$tmdbId/season/$seasonNumber/episode',
      language: language,
      cancelWhen: cancelWhen,
    );
    final episodes = res.json?['episodes'];
    if (episodes is! List) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    try {
      return [
        for (final e in episodes)
          if (e is Map<String, dynamic>) TvSeasonEpisode.fromJson(e),
      ];
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  Future<TvShowProgress?> progress(
    String userId,
    String tvShowId, {
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'tv/progress',
      query: {'userId': userId, 'tvShowId': tvShowId},
      cancelWhen: cancelWhen,
    );
    try {
      final items = res.json?['tvShowProgresses'];
      final list = items is Map<String, dynamic> ? items['items'] : items;
      if (list is! List) return null;
      for (final item in list) {
        if (item is Map<String, dynamic>) return TvShowProgress.fromJson(item);
      }
      return null;
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  Future<void> saveProgress(
    String tvShowId, {
    required String status,
    int? watchCount,
    String? startedAt,
    String? completedAt,
    String? notes,
  }) => _api.requestJson(
    'POST',
    'tv/progress',
    body: {
      'tvShowId': tvShowId,
      'status': status,
      'watchCount': ?watchCount,
      'startedAt': ?startedAt,
      'completedAt': ?completedAt,
      'notes': ?notes,
    },
  );

  Future<void> deleteProgress(String progressId) =>
      _api.requestJson('DELETE', 'tv/progress/$progressId');

  Future<void> resetTracking(String tvShowId) =>
      _api.requestJson('DELETE', 'tv/tracking/$tvShowId');

  Future<void> refresh(int tmdbId) =>
      _api.requestJson('POST', 'tv/refresh', body: {'tmdbId': tmdbId});

  Future<List<TvEpisodeWatch>> episodeWatch(
    String userId,
    String tvShowId, {
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'tv/episode/watch',
      query: {'userId': userId, 'tvShowId': tvShowId},
      cancelWhen: cancelWhen,
    );
    final items = res.json?['tvShowEpisodeWatch'];
    final list = items is Map<String, dynamic> ? items['items'] : items;
    if (list is! List) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    try {
      return [
        for (final item in list)
          if (item is Map<String, dynamic>) TvEpisodeWatch.fromJson(item),
      ];
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  Future<void> watchEpisodes(
    String tvShowId,
    List<({int season, int episode})> episodes,
  ) => _api.requestJson(
    'POST',
    'tv/episode/watch',
    body: {
      'tvShowId': tvShowId,
      'episodes': [
        for (final e in episodes)
          {'season': e.season, 'episode': e.episode, 'status': 'Completed'},
      ],
    },
  );

  Future<void> unwatchEpisode(String tvShowId, int season, int episode) =>
      _api.requestJson(
        'DELETE',
        'tv/episode/watch',
        body: {'tvShowId': tvShowId, 'season': season, 'episode': episode},
      );

  Future<void> watchAll(String tvShowId) => _api.requestJson(
    'POST',
    'tv/episode/watch/all',
    body: {'tvShowId': tvShowId},
  );

  Future<void> unwatchAll(String tvShowId) => _api.requestJson(
    'DELETE',
    'tv/episode/watch/all',
    body: {'tvShowId': tvShowId},
  );

  Future<WatchProviders> watchProviders(
    int tmdbId, {
    String? region,
    String? language,
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'tv/detail/$tmdbId/watch/provider',
      query: {'region': ?region},
      language: language,
      cancelWhen: cancelWhen,
    );
    final providers = res.json?['watchProviders'];
    if (providers is! Map<String, dynamic>) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    try {
      return WatchProviders.fromJson(providers);
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  Future<List<WatchProviderRegion>> watchProviderRegions({
    String? language,
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'tv/watch/provider/region',
      language: language,
      cancelWhen: cancelWhen,
    );
    final regions = res.json?['regions'];
    if (regions is! List) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    try {
      return [
        for (final r in regions)
          if (r is Map<String, dynamic>) WatchProviderRegion.fromJson(r),
      ];
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }
}
