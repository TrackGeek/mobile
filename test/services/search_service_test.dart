import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trackgeek/app/api_config.dart';
import 'package:trackgeek/models/api_exception.dart';
import 'package:trackgeek/models/media_type.dart';
import 'package:trackgeek/models/search_item.dart';
import 'package:trackgeek/services/api_client.dart';
import 'package:trackgeek/services/search_service.dart';

void main() {
  Map<String, dynamic> page(
    String envelope, {
    List<Map<String, dynamic>> items = const [],
    int? pages = 0,
    int? itemsPerPage,
    int inPage = 1,
  }) => {
    envelope: {
      'total': null,
      'pages': pages,
      'inPage': inPage,
      'itemsInPage': items.length,
      'itemsPerPage': itemsPerPage,
      'items': items,
    },
  };

  SearchService service(Map<String, dynamic> response) {
    final api = ApiClient(
      config: ApiConfig(baseUrl: 'https://api.example.test'),
      client: MockClient(
        (_) async =>
            http.Response.bytes(utf8.encode(jsonEncode(response)), 200),
      ),
    );
    addTearDown(api.close);
    return SearchService(api);
  }

  test('maps each media envelope and provider IDs', () async {
    final cases = [
      (
        const MediaSearchKind(MediaType.anime),
        'animes',
        {'malId': 20, 'title': 'Naruto'},
      ),
      (
        const MediaSearchKind(MediaType.manga),
        'mangas',
        {'anilistId': 34268, 'malId': 4268, 'title': 'A'},
      ),
      (
        const MediaSearchKind(MediaType.movie),
        'movies',
        {'tmdbId': 185, 'title': 'Clockwork'},
      ),
      (
        const MediaSearchKind(MediaType.tv),
        'tvShows',
        {'tmdbId': 7, 'name': 'Show'},
      ),
      (
        const MediaSearchKind(MediaType.game),
        'games',
        {'igdbId': 1020, 'name': 'GTA'},
      ),
      (
        const MediaSearchKind(MediaType.book),
        'books',
        {'hardcoverId': 42, 'title': 'Book'},
      ),
    ];
    for (final (kind, envelope, item) in cases) {
      item['isAdult'] = false;
      final result = await service(
        page(envelope, items: [item], pages: 1, itemsPerPage: 20),
      ).search(kind);
      expect(result.items.single.mediaType, kind.type);
      expect(result.items.single.target, SearchTarget.media);
    }
  });

  test('prefers anilistId over malId for manga detail ids', () async {
    final result = await service(
      page(
        'mangas',
        items: [
          {'anilistId': 34268, 'malId': 4268, 'title': 'A', 'isAdult': false},
        ],
      ),
    ).search(const MediaSearchKind(MediaType.manga));
    expect(result.items.single.id, '34268');
  });

  test('maps users and people', () async {
    final users = await service(
      page(
        'users',
        items: [
          {
            'id': 'u1',
            'username': 'ana',
            'name': 'Ana',
            'profile': {'avatarUrl': 'https://x.test/a.jpg'},
          },
        ],
      ),
    ).search(const UserSearchKind());
    expect(users.items.single.target, SearchTarget.user);
    expect(users.items.single.id, 'u1');
    expect(users.items.single.username, 'ana');
    expect(users.items.single.imageUrl, 'https://x.test/a.jpg');

    final people = await service(
      page(
        'people',
        items: [
          {'tmdbId': 9, 'name': 'A Martinez', 'knownForDepartment': 'Acting'},
        ],
      ),
    ).search(const PersonSearchKind());
    expect(people.items.single.target, SearchTarget.person);
    expect(people.items.single.subtitle, 'Acting');
  });

  test(
    'book envelope without pages still paginates via itemsPerPage',
    () async {
      final result = await service(
        page(
          'books',
          items: [
            {'hardcoverId': 1, 'title': 'A', 'isAdult': false},
          ],
          pages: null,
          itemsPerPage: 1,
        ),
      ).search(const MediaSearchKind(MediaType.book));
      expect(result.hasNextPage, isTrue);
    },
  );

  test('user search sends itemsPerPage and filters as query params', () async {
    final requested = <Uri>[];
    final api = ApiClient(
      config: ApiConfig(baseUrl: 'https://api.example.test'),
      client: MockClient((request) async {
        requested.add(request.url);
        return http.Response.bytes(utf8.encode(jsonEncode(page('users'))), 200);
      }),
    );
    addTearDown(api.close);
    await SearchService(api).search(
      const UserSearchKind(),
      query: 'ana',
      filters: const {'genres': 'Action,Drama'},
    );
    final params = requested.single.queryParameters;
    expect(params['query'], 'ana');
    expect(params['itemsPerPage'], '18');
    expect(params['genres'], 'Action,Drama');
    expect(params.containsKey('page'), isFalse);
  });

  test('rejects malformed envelopes', () async {
    for (final response in [
      <String, dynamic>{},
      {'movies': <String, dynamic>{}},
      page(
        'movies',
        items: [
          {'title': 'No provider id'},
        ],
      ),
    ]) {
      await expectLater(
        service(response).search(const MediaSearchKind(MediaType.movie)),
        throwsA(
          isA<ApiException>().having(
            (e) => e.failure,
            'failure',
            ApiFailure.invalidResponse,
          ),
        ),
      );
    }
  });
}
