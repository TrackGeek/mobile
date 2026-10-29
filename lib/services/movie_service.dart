import '../models/api_exception.dart';
import '../models/movie_detail.dart';
import 'api_client.dart';

class MovieService {
  const MovieService(this._api);

  final ApiClient _api;

  Future<MovieDetail> detail(
    int tmdbId, {
    String language = 'en-US',
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'movie/detail/$tmdbId',
      language: language,
      cancelWhen: cancelWhen,
    );
    final movie = res.json?['movie'];
    if (movie is! Map<String, dynamic>) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    try {
      return MovieDetail.fromJson(movie);
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  Future<MovieFranchise> franchise(
    String slug, {
    String language = 'en-US',
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'movie/franchise/$slug',
      language: language,
      cancelWhen: cancelWhen,
    );
    final franchise = res.json?['franchise'];
    if (franchise is! Map<String, dynamic>) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    try {
      return MovieFranchise.fromJson(franchise);
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  Future<MovieProgress?> progress(
    String userId,
    String movieId, {
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'movie/progress',
      query: {'userId': userId, 'movieId': movieId},
      cancelWhen: cancelWhen,
    );
    try {
      final items = res.json?['movieProgresses'];
      final list = items is Map<String, dynamic> ? items['items'] : items;
      if (list is! List) return null;
      for (final item in list) {
        if (item is Map<String, dynamic>) return MovieProgress.fromJson(item);
      }
      return null;
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  Future<void> saveProgress(
    String movieId, {
    required String status,
    int? watchCount,
  }) => _api.requestJson(
    'POST',
    'movie/progress',
    body: {'movieId': movieId, 'status': status, 'watchCount': ?watchCount},
  );

  Future<void> deleteProgress(String progressId) =>
      _api.requestJson('DELETE', 'movie/progress/$progressId');

  Future<void> refresh(int tmdbId) =>
      _api.requestJson('POST', 'movie/refresh', body: {'id': tmdbId});

  Future<WatchProviders> watchProviders(
    int tmdbId, {
    String? region,
    String language = 'en-US',
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'movie/detail/$tmdbId/watch/provider',
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
    String language = 'en-US',
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'movie/watch/provider/region',
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
