import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trackgeek/app/api_config.dart';
import 'package:trackgeek/models/api_exception.dart';
import 'package:trackgeek/services/api_client.dart';
import 'package:trackgeek/services/game_service.dart';

void main() {
  GameService service(
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
    return GameService(api);
  }

  final detailResponse = {
    'game': {
      'id': 'game-uuid',
      'igdbId': 1942,
      'slug': 'the-witcher-3-wild-hunt',
      'name': 'The Witcher 3: Wild Hunt',
      'coverUrl': 'https://images.igdb.com/t_cover_big/cover.jpg',
      'summary': 'RPG',
      'storyline': 'Geralt searches for Ciri',
      'firstReleaseDate': '2015-05-19T00:00:00.000Z',
      'gameStatus': 'Released',
      'tgReviewScore': 4.7,
      'genres': [
        {'name': 'Role-playing (RPG)'},
      ],
      'themes': ['Fantasy', 'Open world'],
      'platforms': [
        {'name': 'PC (Microsoft Windows)', 'slug': 'pc-microsoft-windows'},
        {'name': 'PlayStation 4', 'slug': 'playstation-4'},
      ],
      'gameModes': [
        {'name': 'Single player'},
      ],
      'playerPerspectives': [
        {'name': 'Third person'},
      ],
      'gameEngines': [
        {'name': 'REDengine 3'},
      ],
      'involvedCompanies': [
        {
          'companyId': 58,
          'companyName': 'CD Projekt RED',
          'developer': true,
          'publisher': true,
        },
      ],
      'websites': [
        {'name': 'Steam', 'url': 'https://store.steampowered.com/app/292030'},
      ],
      'videos': [
        {'checksum': 'abc', 'name': 'Trailer', 'videoId': 'yt12345678a'},
      ],
      'screenshots': [
        {'checksum': 'def', 'imageId': 'shot1'},
      ],
      'franchises': [
        {'id': 963, 'name': 'The Witcher', 'slug': 'the-witcher'},
      ],
      'parentGame': {'id': 100, 'name': 'Parent', 'coverUrl': 'p.jpg'},
      'sequels': [
        {'id': 200, 'name': 'Sequel', 'coverUrl': 's.jpg'},
      ],
      'lastRefreshedAt': '2024-01-01T00:00:00.000Z',
      'progressStats': {
        'planToPlay': {'count': 10, 'percentage': 50.0},
        'playing': {'count': 6, 'percentage': 30.0},
        'completed': {'count': 3, 'percentage': 15.0},
        'dropped': {'count': 1, 'percentage': 5.0},
      },
    },
  };

  test(
    'detail calls game/detail/igdbId and parses the game envelope',
    () async {
      final requests = <http.BaseRequest>[];
      final game = await service(detailResponse, requests).detail(1942);

      expect(requests.single.url.path, endsWith('/game/detail/1942'));
      expect(game.id, 'game-uuid');
      expect(game.igdbId, 1942);
      expect(game.slug, 'the-witcher-3-wild-hunt');
      expect(
        game.displayCoverUrl,
        'https://images.igdb.com/t_original/cover.jpg',
      );
      expect(game.genres, ['Role-playing (RPG)']);
      expect(game.themes, ['Fantasy', 'Open world']);
      expect(game.platforms.length, 2);
      expect(game.platformNames.first, 'PC (Microsoft Windows)');
      expect(game.gameModes, ['Single player']);
      expect(game.playerPerspectives, ['Third person']);
      expect(game.gameEngines, ['REDengine 3']);
      expect(game.developers.single.name, 'CD Projekt RED');
      expect(game.publishers.single.companyId, 58);
      expect(game.websites.single.name, 'Steam');
      expect(game.videos.single.videoId, 'yt12345678a');
      expect(game.franchises.single.slug, 'the-witcher');
      expect(game.parentGame?.id, 100);
      expect(game.sequels.single.name, 'Sequel');
      expect(game.lastRefreshedAt, isNotNull);
      expect(game.progressStats?.planToPlay.count, 10);
    },
  );

  test('detail rejects malformed response', () async {
    await expectLater(
      service({}, []).detail(1),
      throwsA(
        isA<ApiException>().having(
          (e) => e.failure,
          'failure',
          ApiFailure.invalidResponse,
        ),
      ),
    );
  });

  test('franchise calls game/franchise/slug and parses games', () async {
    final requests = <http.BaseRequest>[];
    final franchise = await service({
      'franchise': {
        'id': 963,
        'name': 'The Witcher',
        'slug': 'the-witcher',
        'bannerUrl': 'https://img/banner.jpg',
        'games': [
          {
            'igdbId': 1942,
            'name': 'The Witcher 3: Wild Hunt',
            'coverUrl': 'https://img/cover.jpg',
            'tgReviewScore': 4.7,
          },
        ],
      },
    }, requests).franchise('the-witcher');

    expect(requests.single.url.path, endsWith('/game/franchise/the-witcher'));
    expect(franchise.name, 'The Witcher');
    expect(franchise.bannerUrl, 'https://img/banner.jpg');
    expect(franchise.games.single.igdbId, 1942);
    expect(franchise.games.single.tgReviewScore, 4.7);
  });

  test('progress sends userId and gameId query params', () async {
    final requests = <http.BaseRequest>[];
    final progress = await service({
      'gameProgresses': {
        'items': [
          {
            'id': 'p1',
            'status': 'Playing',
            'hoursPlayed': 42,
            'playCount': 1,
            'platforms': ['pc-microsoft-windows'],
            'completion': 'mainStory',
          },
        ],
      },
    }, requests).progress('u1', 'g1');

    final uri = requests.single.url;
    expect(uri.path, endsWith('/game/progress'));
    expect(uri.queryParameters['userId'], 'u1');
    expect(uri.queryParameters['gameId'], 'g1');
    expect(progress?.id, 'p1');
    expect(progress?.status, 'Playing');
    expect(progress?.hoursPlayed, 42);
    expect(progress?.platforms, ['pc-microsoft-windows']);
  });

  test('progress returns null for empty list', () async {
    final progress = await service({
      'gameProgresses': {'items': <dynamic>[]},
    }, []).progress('u1', 'g1');
    expect(progress, isNull);
  });

  test('saveProgress posts status and fields', () async {
    final requests = <http.BaseRequest>[];
    await service({}, requests).saveProgress(
      'g1',
      status: 'Completed',
      playCount: 2,
      completion: '100%',
      platforms: ['PlayStation 4'],
      hoursPlayed: 120,
      notes: 'done',
      startedAt: '2024-01-01T00:00:00.000',
      completedAt: '2024-02-01T00:00:00.000',
    );

    final request = requests.single;
    expect(request.method, 'POST');
    expect(request.url.path, endsWith('/game/progress'));
    expect(jsonDecode((request as http.Request).body), {
      'gameId': 'g1',
      'status': 'Completed',
      'playCount': 2,
      'completion': '100%',
      'platforms': ['PlayStation 4'],
      'hoursPlayed': 120,
      'notes': 'done',
      'startedAt': '2024-01-01T00:00:00.000',
      'completedAt': '2024-02-01T00:00:00.000',
    });
  });

  test('saveProgress omits null optional fields', () async {
    final requests = <http.BaseRequest>[];
    await service({}, requests).saveProgress('g1', status: 'Planning');

    final body = jsonDecode((requests.single as http.Request).body);
    expect(body, {'gameId': 'g1', 'status': 'Planning'});
  });

  test('deleteProgress calls DELETE game/progress/id', () async {
    final requests = <http.BaseRequest>[];
    await service({}, requests).deleteProgress('p1');
    expect(requests.single.method, 'DELETE');
    expect(requests.single.url.path, endsWith('/game/progress/p1'));
  });

  test('resetTracking calls DELETE game/tracking/gameId', () async {
    final requests = <http.BaseRequest>[];
    await service({}, requests).resetTracking('g1');
    expect(requests.single.method, 'DELETE');
    expect(requests.single.url.path, endsWith('/game/tracking/g1'));
  });

  test('refresh posts igdbId', () async {
    final requests = <http.BaseRequest>[];
    await service({}, requests).refresh(1942);
    final request = requests.single;
    expect(request.method, 'POST');
    expect(request.url.path, endsWith('/game/refresh'));
    expect(jsonDecode((request as http.Request).body), {'igdbId': 1942});
  });

  test('screenshots sends query params and parses page', () async {
    final requests = <http.BaseRequest>[];
    final page = await service({
      'screenshots': {
        'items': [
          {
            'id': 's1',
            'url': 'https://img/shot.jpg',
            'type': 'Image',
            'isSpoiler': false,
            'description': 'nice',
            'game': {'id': 'g1', 'igdbId': 1942, 'name': 'W3'},
          },
        ],
        'total': 1,
        'pages': 1,
        'inPage': 1,
        'itemsInPage': 1,
        'itemsPerPage': 20,
      },
    }, requests).screenshots(userId: 'u1', gameId: 'g1', itemsPerPage: 20);

    final uri = requests.single.url;
    expect(uri.path, endsWith('/game/screenshot/'));
    expect(uri.queryParameters['userId'], 'u1');
    expect(uri.queryParameters['gameId'], 'g1');
    expect(page.items.single.id, 's1');
    expect(page.items.single.gameIgdbId, 1942);
  });

  test('createScreenshot posts fields and parses screenshot', () async {
    final requests = <http.BaseRequest>[];
    final shot =
        await service({
          'screenshot': {
            'id': 's1',
            'url': 'https://img/shot.jpg',
            'type': 'Video',
            'isSpoiler': true,
          },
        }, requests).createScreenshot(
          gameId: 'g1',
          url: 'https://youtu.be/abc',
          type: 'Video',
          description: 'clip',
          isSpoiler: true,
        );

    final request = requests.single;
    expect(request.method, 'POST');
    expect(request.url.path, endsWith('/game/screenshot'));
    expect(jsonDecode((request as http.Request).body), {
      'gameId': 'g1',
      'url': 'https://youtu.be/abc',
      'type': 'Video',
      'description': 'clip',
      'isSpoiler': true,
    });
    expect(shot.id, 's1');
    expect(shot.type, 'Video');
    expect(shot.isSpoiler, isTrue);
  });

  test('updateScreenshot PATCHes and parses screenshot', () async {
    final requests = <http.BaseRequest>[];
    final shot = await service({
      'screenshot': {
        'id': 's1',
        'url': 'https://img/shot.jpg',
        'type': 'Image',
        'isSpoiler': false,
        'description': 'edited',
      },
    }, requests).updateScreenshot('s1', description: 'edited');

    final request = requests.single;
    expect(request.method, 'PATCH');
    expect(request.url.path, endsWith('/game/screenshot/s1'));
    expect(shot.description, 'edited');
  });

  test('deleteScreenshot calls DELETE game/screenshot/id', () async {
    final requests = <http.BaseRequest>[];
    await service({}, requests).deleteScreenshot('s1');
    expect(requests.single.method, 'DELETE');
    expect(requests.single.url.path, endsWith('/game/screenshot/s1'));
  });
}
