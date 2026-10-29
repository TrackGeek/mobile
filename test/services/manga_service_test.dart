import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trackgeek/app/api_config.dart';
import 'package:trackgeek/models/api_exception.dart';
import 'package:trackgeek/services/api_client.dart';
import 'package:trackgeek/services/manga_service.dart';

void main() {
  MangaService service(
    Map<String, dynamic> response,
    List<http.BaseRequest> requests,
  ) {
    final api = ApiClient(
      config: ApiConfig(baseUrl: 'https://api.example.test'),
      client: MockClient((request) async {
        requests.add(request);
        return http.Response.bytes(utf8.encode(jsonEncode(response)), 200);
      }),
    );
    addTearDown(api.close);
    return MangaService(api);
  }

  final detailResponse = {
    'manga': {
      'id': 'manga-uuid',
      'anilistId': 30013,
      'malId': 13,
      'url': 'https://anilist.co/manga/30013',
      'imageUrl': 'https://img/cover.jpg',
      'title': 'One Piece',
      'titles': [
        {'type': 'Default', 'title': 'One Piece'},
        {'type': 'Native', 'title': 'ONE PIECE'},
        {'type': 'Synonym', 'title': 'OP'},
      ],
      'type': 'Manga',
      'status': 'Publishing',
      'numberOfChapters': 1100,
      'numberOfVolumes': 105,
      'published': {
        'from': '1997-07-22T00:00:00.000Z',
        'to': null,
        'string': 'Jul 22, 1997 to Present',
      },
      'synopsis': 'Pirates.',
      'authors': [
        {
          'anilistId': 189,
          'name': 'Eiichiro Oda',
          'role': 'Story & Art',
          'imageUrl': 'https://img/oda.jpg',
        },
      ],
      'serializations': [
        {
          'anilistId': 83,
          'name': 'Shounen Jump',
          'role': null,
          'imageUrl': null,
        },
      ],
      'genres': ['Action', 'Adventure'],
      'themes': ['Pirates'],
      'demographics': ['Shounen'],
      'external': [
        {'name': 'Twitter', 'url': 'https://x.com/opcom'},
      ],
      'characters': [
        {'anilistId': 40, 'name': 'Luffy', 'imageUrl': null, 'role': 'Main'},
      ],
      'relations': {
        'nodes': [
          {
            'id': '30013',
            'name': 'One Piece',
            'image': 'https://img/cover.jpg',
            'link': '/manga/30013',
            'relationShip': 'Now',
          },
          {
            'id': '21',
            'name': 'One Piece (Anime)',
            'image': '',
            'link': '/anime/21',
            'relationShip': 'Adaptation',
          },
        ],
        'edges': [
          {'id': '30013-21', 'source': '30013', 'target': '21'},
        ],
      },
      'tgReviewScore': 4.6,
      'lastRefreshedAt': '2026-10-01T10:00:00.000Z',
      'progressStats': {
        'planning': {'count': 5, 'percentage': 25.0},
        'reading': {'count': 10, 'percentage': 50.0},
        'completed': {'count': 4, 'percentage': 20.0},
        'paused': {'count': 0, 'percentage': 0.0},
        'dropped': {'count': 1, 'percentage': 5.0},
      },
    },
  };

  test('detail calls manga/detail and parses the manga envelope', () async {
    final requests = <http.BaseRequest>[];
    final manga = await service(detailResponse, requests).detail(30013);

    expect(requests.single.url.path, endsWith('/manga/detail/30013'));
    expect(manga.id, 'manga-uuid');
    expect(manga.anilistId, 30013);
    expect(manga.malId, 13);
    expect(manga.title, 'One Piece');
    expect(manga.numberOfChapters, 1100);
    expect(manga.published?.string, 'Jul 22, 1997 to Present');
    expect(manga.authors.single.name, 'Eiichiro Oda');
    expect(manga.authors.single.label, 'Eiichiro Oda (Story & Art)');
    expect(manga.serializations.single.name, 'Shounen Jump');
    expect(manga.cast.length, 2);
    expect(manga.characters.single.name, 'Luffy');
    expect(manga.relations?.nodes.length, 2);
    expect(manga.external.single.name, 'Twitter');
    expect(manga.tgReviewScore, 4.6);
    expect(manga.progressStats?.reading.count, 10);
  });

  test('alternativeTitles dedupes against the main title', () async {
    final manga = await service(detailResponse, []).detail(30013);

    final alt = manga.alternativeTitles;
    expect(alt.length, 1);
    expect(alt.single.title, 'OP');
  });

  test('detail throws invalidResponse on a malformed payload', () async {
    expect(
      () => service({'manga': 'nope'}, []).detail(30013),
      throwsA(isA<ApiException>()),
    );
  });

  test(
    'progress queries with userId and mangaId and picks first item',
    () async {
      final requests = <http.BaseRequest>[];
      final response = {
        'mangaProgresses': {
          'items': [
            {
              'id': 'prog-1',
              'status': 'Reading',
              'chaptersRead': 42,
              'readCount': 1,
              'startedAt': '2026-01-01T00:00:00.000Z',
              'completedAt': null,
            },
          ],
        },
      };
      final progress = await service(
        response,
        requests,
      ).progress('user-1', 'manga-uuid');

      final uri = requests.single.url;
      expect(uri.path, endsWith('/manga/progress'));
      expect(uri.queryParameters['userId'], 'user-1');
      expect(uri.queryParameters['mangaId'], 'manga-uuid');
      expect(progress?.id, 'prog-1');
      expect(progress?.status, 'Reading');
      expect(progress?.chaptersRead, 42);
      expect(progress?.readCount, 1);
    },
  );

  test('progress returns null when no items exist', () async {
    final progress = await service({
      'mangaProgresses': {'items': <dynamic>[]},
    }, []).progress('user-1', 'manga-uuid');

    expect(progress, isNull);
  });

  test('saveProgress posts status with optional fields omitted', () async {
    final requests = <http.BaseRequest>[];
    await service({}, requests).saveProgress('manga-uuid', status: 'Planning');

    final request = requests.single;
    expect(request.method, 'POST');
    expect(request.url.path, endsWith('/manga/progress'));
    final body = jsonDecode((request as http.Request).body);
    expect(body['mangaId'], 'manga-uuid');
    expect(body['status'], 'Planning');
    expect(body.containsKey('chaptersRead'), isFalse);
    expect(body.containsKey('completedAt'), isFalse);
  });

  test('saveProgress sends counts and dates when provided', () async {
    final requests = <http.BaseRequest>[];
    await service({}, requests).saveProgress(
      'manga-uuid',
      status: 'Completed',
      chaptersRead: 1100,
      readCount: 2,
      startedAt: '2026-01-01T00:00:00.000Z',
      completedAt: '2026-10-01T00:00:00.000Z',
    );

    final body = jsonDecode((requests.single as http.Request).body);
    expect(body['chaptersRead'], 1100);
    expect(body['readCount'], 2);
    expect(body['startedAt'], '2026-01-01T00:00:00.000Z');
    expect(body['completedAt'], '2026-10-01T00:00:00.000Z');
  });

  test('deleteProgress deletes by progress id', () async {
    final requests = <http.BaseRequest>[];
    await service({}, requests).deleteProgress('prog-1');

    expect(requests.single.method, 'DELETE');
    expect(requests.single.url.path, endsWith('/manga/progress/prog-1'));
  });

  test('refresh posts the anilist id', () async {
    final requests = <http.BaseRequest>[];
    await service({}, requests).refresh(30013);

    final request = requests.single;
    expect(request.method, 'POST');
    expect(request.url.path, endsWith('/manga/refresh'));
    expect(jsonDecode((request as http.Request).body)['anilistId'], 30013);
  });
}
