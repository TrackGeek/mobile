import '../models/api_exception.dart';
import '../models/favorite.dart';
import '../models/paginated_page.dart';
import 'api_client.dart';

enum FavoriteTarget { anime, manga, tv, movie, game, book, person }

const _favoriteType = {
  FavoriteTarget.anime: 'Anime',
  FavoriteTarget.manga: 'Manga',
  FavoriteTarget.tv: 'TVShow',
  FavoriteTarget.movie: 'Movie',
  FavoriteTarget.game: 'Game',
  FavoriteTarget.book: 'Book',
  FavoriteTarget.person: 'Person',
};

const _favoriteIdField = {
  FavoriteTarget.anime: 'animeId',
  FavoriteTarget.manga: 'mangaId',
  FavoriteTarget.tv: 'tvShowId',
  FavoriteTarget.movie: 'movieId',
  FavoriteTarget.game: 'gameId',
  FavoriteTarget.book: 'bookId',
  FavoriteTarget.person: 'personId',
};

class FavoriteService {
  const FavoriteService(this._api);

  final ApiClient _api;

  Map<String, dynamic> _request(FavoriteTarget target, String id) => {
    'type': _favoriteType[target],
    _favoriteIdField[target]!: id,
  };

  Future<bool> status(
    FavoriteTarget target,
    String id, {
    String language = 'en-US',
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'favorite/status',
      query: {'type': _favoriteType[target]!, _favoriteIdField[target]!: id},
      language: language,
      cancelWhen: cancelWhen,
    );
    final favorited = res.json?['favorited'];
    if (favorited is! bool) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    return favorited;
  }

  Future<PaginatedPage<Favorite>> favoritesByUser(
    String userId, {
    int page = 1,
    int itemsPerPage = 20,
    String query = '',
    String language = 'en-US',
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'favorite/user/$userId',
      query: {
        'page': '$page',
        'itemsPerPage': '$itemsPerPage',
        if (query.trim().isNotEmpty) 'query': query.trim(),
      },
      language: language,
      cancelWhen: cancelWhen,
    );
    try {
      return PaginatedPage.fromJson(
        res.json?['favorites'] as Map<String, dynamic>,
        Favorite.fromJson,
      );
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    } on FormatException {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  Future<void> remove(
    FavoriteTarget target,
    String id, {
    String language = 'en-US',
  }) => _api.requestJson(
    'DELETE',
    'favorite',
    body: _request(target, id),
    language: language,
  );

  Future<void> toggle(
    FavoriteTarget target,
    String id,
    bool isFavorited, {
    String language = 'en-US',
  }) async {
    await _api.requestJson(
      isFavorited ? 'DELETE' : 'POST',
      'favorite',
      body: _request(target, id),
      language: language,
    );
  }
}
