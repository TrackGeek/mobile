import '../models/media_type.dart';
import '../models/paginated_page.dart';
import '../models/api_exception.dart';
import '../models/search_item.dart';
import 'api_client.dart';

sealed class SearchKind {
  const SearchKind();

  String get path;
  String get envelope;
  Map<String, String> get extraParams => const {};
  SearchItem Function(Map<String, dynamic>) get decode;
}

final class MediaSearchKind extends SearchKind {
  const MediaSearchKind(this.type);

  final MediaType type;

  @override
  String get path => '${type.slug}/search';

  @override
  String get envelope => type.searchEnvelope;

  @override
  SearchItem Function(Map<String, dynamic>) get decode =>
      (json) => SearchItem.media(type, json);
}

final class UserSearchKind extends SearchKind {
  const UserSearchKind();

  @override
  String get path => 'user/search';

  @override
  String get envelope => 'users';

  @override
  Map<String, String> get extraParams => const {'itemsPerPage': '18'};

  @override
  SearchItem Function(Map<String, dynamic>) get decode => SearchItem.user;
}

final class PersonSearchKind extends SearchKind {
  const PersonSearchKind();

  @override
  String get path => 'person/search';

  @override
  String get envelope => 'people';

  @override
  SearchItem Function(Map<String, dynamic>) get decode => SearchItem.person;
}

abstract interface class SearchGateway {
  Future<PaginatedPage<SearchItem>> search(
    SearchKind kind, {
    String query,
    int page,
    String language,
    Map<String, String> filters,
    Future<void>? cancelWhen,
  });
}

class SearchService implements SearchGateway {
  const SearchService(this._api);

  final ApiClient _api;

  @override
  Future<PaginatedPage<SearchItem>> search(
    SearchKind kind, {
    String query = '',
    int page = 1,
    String? language,
    Map<String, String> filters = const {},
    Future<void>? cancelWhen,
  }) async {
    if (page < 1) throw ArgumentError.value(page, 'page');
    final json = await _api.getJson(
      kind.path,
      query: {
        if (query.isNotEmpty) 'query': query,
        if (page > 1) 'page': '$page',
        ...kind.extraParams,
        ...filters,
      },
      language: language,
      cancelWhen: cancelWhen,
    );
    try {
      return PaginatedPage.fromJson(
        json[kind.envelope] as Map<String, dynamic>,
        kind.decode,
      );
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    } on FormatException {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }
}
