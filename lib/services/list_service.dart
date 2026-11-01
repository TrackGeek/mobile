import '../models/api_exception.dart';
import '../models/media_type.dart';
import '../models/paginated_page.dart';
import '../models/user_list.dart';
import 'api_client.dart';

const listApiType = {
  MediaType.movie: 'Movie',
  MediaType.tv: 'TVShow',
  MediaType.game: 'Game',
  MediaType.anime: 'Anime',
  MediaType.manga: 'Manga',
  MediaType.book: 'Book',
};

const listMediaIdField = {
  MediaType.movie: 'movieId',
  MediaType.tv: 'tvShowId',
  MediaType.game: 'gameId',
  MediaType.anime: 'animeId',
  MediaType.manga: 'mangaId',
  MediaType.book: 'bookId',
};

class ListService {
  const ListService(this._api);

  final ApiClient _api;

  Future<PaginatedPage<UserList>> userLists(
    String userId, {
    required MediaType type,
    int page = 1,
    int itemsPerPage = 50,
    String? language,
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'list/user/$userId',
      query: {
        'type': listApiType[type]!,
        'page': '$page',
        'itemsPerPage': '$itemsPerPage',
      },
      language: language,
      cancelWhen: cancelWhen,
    );
    try {
      return PaginatedPage.fromJson(
        res.json?['lists'] as Map<String, dynamic>,
        UserList.fromJson,
      );
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    } on FormatException {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  Future<List<String>> listStatus(
    MediaType type, {
    required String mediaId,
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'list/status',
      query: {'type': listApiType[type]!, listMediaIdField[type]!: mediaId},
      cancelWhen: cancelWhen,
    );
    final ids = res.json?['listIds'];
    if (ids is! List) throw const ApiException(ApiFailure.invalidResponse);
    return [for (final id in ids) '$id'];
  }

  Future<PaginatedPage<UserList>> containingLists(
    MediaType type, {
    required String mediaId,
    int page = 1,
    int itemsPerPage = 20,
    String? language,
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'list/containing',
      query: {
        'type': listApiType[type]!,
        listMediaIdField[type]!: mediaId,
        'page': '$page',
        'itemsPerPage': '$itemsPerPage',
      },
      language: language,
      cancelWhen: cancelWhen,
    );
    try {
      return PaginatedPage.fromJson(
        res.json?['lists'] as Map<String, dynamic>,
        UserList.fromJson,
      );
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    } on FormatException {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  Future<void> createList(
    String userId, {
    required String name,
    required MediaType type,
  }) => _api.requestJson(
    'POST',
    'list',
    body: {'name': name, 'userId': userId, 'type': listApiType[type]!},
  );

  Future<void> toggleListItem(
    String listId, {
    required MediaType type,
    required String mediaId,
    required String userId,
    required bool isMember,
  }) => _api.requestJson(
    isMember ? 'DELETE' : 'POST',
    'list/$listId/item',
    body: {
      'type': listApiType[type]!,
      'listId': listId,
      'userId': userId,
      listMediaIdField[type]!: mediaId,
    },
  );

  Future<PaginatedPage<UserListGroup>> listsByUser(
    String userId, {
    String query = '',
    int page = 1,
    int itemsPerPage = 10,
    String? language,
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'list/user/$userId',
      query: {
        'grouped': 'true',
        'page': '$page',
        'itemsPerPage': '$itemsPerPage',
        if (query.trim().isNotEmpty) 'query': query.trim(),
      },
      language: language,
      cancelWhen: cancelWhen,
    );
    try {
      return PaginatedPage.fromJson(
        res.json?['lists'] as Map<String, dynamic>,
        UserListGroup.fromJson,
      );
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    } on FormatException {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  Future<PaginatedPage<UserListItem>> listItems(
    String listId, {
    int page = 1,
    int itemsPerPage = 10,
    String? language,
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'list/$listId/item',
      query: {'page': '$page', 'itemsPerPage': '$itemsPerPage'},
      language: language,
      cancelWhen: cancelWhen,
    );
    try {
      return PaginatedPage.fromJson(
        res.json?['listItems'] as Map<String, dynamic>,
        UserListItem.fromJson,
      );
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    } on FormatException {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  Future<void> updateList(String listId, {String? name, String? description}) =>
      _api.requestJson(
        'PATCH',
        'list/$listId',
        body: {'name': ?name, 'description': ?description},
      );

  Future<void> deleteList(String listId) =>
      _api.requestJson('DELETE', 'list/$listId');

  Future<void> removeItem(String listId, String listItemId) => _api.requestJson(
    'DELETE',
    'list/$listId/item',
    body: {'listItemId': listItemId},
  );
}
