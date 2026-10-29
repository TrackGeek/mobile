import 'package:trackgeek/models/api_exception.dart';
import 'package:trackgeek/models/media_type.dart';
import 'package:trackgeek/models/paginated_page.dart';
import 'package:trackgeek/models/search_item.dart';
import 'package:trackgeek/services/search_service.dart';

class FakeSearchGateway implements SearchGateway {
  FakeSearchGateway({
    this.pages = 1,
    this.itemsPerPage = 2,
    this.error,
    this.fixedItems,
  });

  final int pages;
  final int itemsPerPage;
  final List<Map<String, dynamic>>? fixedItems;
  ApiException? error;

  int calls = 0;
  SearchKind? lastKind;
  String lastQuery = '';
  int lastPage = 0;
  Map<String, String> lastFilters = const {};

  @override
  Future<PaginatedPage<SearchItem>> search(
    SearchKind kind, {
    String query = '',
    int page = 1,
    String language = 'en-US',
    Map<String, String> filters = const {},
    Future<void>? cancelWhen,
  }) async {
    calls++;
    lastKind = kind;
    lastQuery = query;
    lastPage = page;
    lastFilters = filters;
    final e = error;
    if (e != null) throw e;
    final items =
        fixedItems ??
        [
          for (var i = 0; i < itemsPerPage; i++)
            switch (kind) {
              UserSearchKind() => {
                'id': 'u$page$i',
                'username': 'user$page$i',
                'name': 'User $page-$i $query'.trim(),
              },
              PersonSearchKind() => {
                'tmdbId': page * 10 + i,
                'name': 'Person $page-$i $query'.trim(),
                'isAdult': false,
              },
              MediaSearchKind(:final type) => switch (type) {
                MediaType.anime || MediaType.manga => {
                  'malId': page * 10 + i + 1,
                  'title': 'Item $page-$i $query'.trim(),
                  'isAdult': false,
                },
                MediaType.movie || MediaType.tv => {
                  'tmdbId': page * 10 + i + 1,
                  'title': 'Item $page-$i $query'.trim(),
                  'isAdult': false,
                },
                MediaType.game => {
                  'igdbId': page * 10 + i + 1,
                  'name': 'Item $page-$i $query'.trim(),
                  'isAdult': false,
                },
                MediaType.book => {
                  'hardcoverId': page * 10 + i + 1,
                  'title': 'Item $page-$i $query'.trim(),
                  'isAdult': false,
                },
              },
            },
        ];
    return PaginatedPage.fromJson({
      'total': pages * items.length,
      'pages': pages,
      'inPage': page,
      'itemsInPage': items.length,
      'itemsPerPage': itemsPerPage,
      'items': items,
    }, kind.decode);
  }
}
