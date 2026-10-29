import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trackgeek/app/api_config.dart';
import 'package:trackgeek/models/api_exception.dart';
import 'package:trackgeek/services/api_client.dart';
import 'package:trackgeek/services/tv_show_service.dart';

void main() {
  TvShowService service(
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
    return TvShowService(api);
  }

  final detailResponse = {
    'tvShow': {
      'id': 'tv-uuid',
      'tmdbId': 1399,
      'name': 'Game of Thrones',
      'originalName': 'Game of Thrones',
      'originalLanguage': 'en',
      'overview': 'Seven noble families fight',
      'tagline': 'Winter is coming',
      'firstAirDate': '2011-04-17T00:00:00.000Z',
      'lastAirDate': '2019-05-19T00:00:00.000Z',
      'status': 'Ended',
      'type': 'Scripted',
      'numberOfSeasons': 8,
      'numberOfEpisodes': 73,
      'episodeRuntime': [60],
      'genres': ['Drama', 'Sci-Fi & Fantasy'],
      'posterUrl': 'https://img/poster.jpg',
      'backdropUrl': 'https://img/backdrop.jpg',
      'productionCompanies': [
        {
          'id': 3268,
          'name': 'HBO',
          'logoUrl': 'https://img/hbo.png',
          'originCountry': 'US',
        },
      ],
      'createdBy': [
        {
          'id': 237,
          'name': 'David Benioff',
          'profileUrl': 'https://img/db.jpg',
          'slug': 'david-benioff',
        },
      ],
      'cast': [
        {
          'id': 12795,
          'name': 'Emilia Clarke',
          'character': 'Daenerys Targaryen',
          'profileUrl': 'https://img/ec.jpg',
          'slug': 'emilia-clarke',
        },
      ],
      'trailerId': 'KPLWWIOCOOQ',
      'external': {'imdb_id': 'tt0944947', 'instagram_id': 'gameofthrones'},
      'backdrops': ['https://img/b1.jpg'],
      'lastRefreshedAt': '2024-01-01T00:00:00.000Z',
      'tgReviewScore': 4.4,
      'progressStats': {
        'planToWatch': {'count': 10, 'percentage': 50.0},
        'watching': {'count': 4, 'percentage': 20.0},
        'completed': {'count': 5, 'percentage': 25.0},
        'dropped': {'count': 1, 'percentage': 5.0},
      },
    },
  };

  test(
    'detail calls tv/detail/tmdbId and parses the tvShow envelope',
    () async {
      final requests = <http.BaseRequest>[];
      final show = await service(detailResponse, requests).detail(1399);

      expect(requests.single.url.path, endsWith('/tv/detail/1399'));
      expect(show.id, 'tv-uuid');
      expect(show.tmdbId, 1399);
      expect(show.name, 'Game of Thrones');
      expect(show.numberOfSeasons, 8);
      expect(show.numberOfEpisodes, 73);
      expect(show.episodeRuntime, [60]);
      expect(show.genres, ['Drama', 'Sci-Fi & Fantasy']);
      expect(show.productionCompanies.single.name, 'HBO');
      expect(show.createdBy.single.name, 'David Benioff');
      expect(show.cast.single.character, 'Daenerys Targaryen');
      expect(show.trailerId, 'KPLWWIOCOOQ');
      expect(show.imdbId, 'tt0944947');
      expect(show.progressStats?.watching.count, 4);
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

  test('seasons calls tv/detail/tmdbId/season and parses list', () async {
    final requests = <http.BaseRequest>[];
    final seasons = await service({
      'seasons': [
        {
          'id': 1,
          'name': 'Season 1',
          'seasonNumber': 1,
          'numberOfEpisodes': 10,
          'airDate': '2011-04-17',
          'posterUrl': 'https://img/s1.jpg',
        },
        {'id': 0, 'name': 'Specials', 'seasonNumber': 0, 'numberOfEpisodes': 3},
      ],
    }, requests).seasons(1399);

    expect(requests.single.url.path, endsWith('/tv/detail/1399/season'));
    expect(seasons.length, 2);
    expect(seasons.first.numberOfEpisodes, 10);
    expect(seasons.last.seasonNumber, 0);
  });

  test('seasonEpisodes calls season episode endpoint', () async {
    final requests = <http.BaseRequest>[];
    final episodes = await service({
      'episodes': [
        {
          'seasonNumber': 1,
          'episodeNumber': 1,
          'name': 'Winter Is Coming',
          'overview': 'o',
          'airDate': '2011-04-17',
          'stillUrl': 'https://img/e1.jpg',
        },
      ],
    }, requests).seasonEpisodes(1399, 1);

    expect(
      requests.single.url.path,
      endsWith('/tv/detail/1399/season/1/episode'),
    );
    expect(episodes.single.name, 'Winter Is Coming');
    expect(episodes.single.stillUrl, 'https://img/e1.jpg');
  });

  test('progress sends userId and tvShowId query params', () async {
    final requests = <http.BaseRequest>[];
    final progress = await service({
      'tvShowProgresses': {
        'items': [
          {
            'id': 'p1',
            'status': 'Watching',
            'watchCount': 1,
            'startedAt': '2024-01-01T00:00:00.000Z',
          },
        ],
      },
    }, requests).progress('u1', 't1');

    final uri = requests.single.url;
    expect(uri.path, endsWith('/tv/progress'));
    expect(uri.queryParameters['userId'], 'u1');
    expect(uri.queryParameters['tvShowId'], 't1');
    expect(progress?.id, 'p1');
    expect(progress?.status, 'Watching');
  });

  test('saveProgress posts tvShowId, status and optional fields', () async {
    final requests = <http.BaseRequest>[];
    await service(
      {},
      requests,
    ).saveProgress('t1', status: 'Completed', watchCount: 2, notes: 'great');

    final request = requests.single;
    expect(request.method, 'POST');
    expect(request.url.path, endsWith('/tv/progress'));
    expect(jsonDecode((request as http.Request).body), {
      'tvShowId': 't1',
      'status': 'Completed',
      'watchCount': 2,
      'notes': 'great',
    });
  });

  test('resetTracking calls DELETE tv/tracking/id', () async {
    final requests = <http.BaseRequest>[];
    await service({}, requests).resetTracking('t1');
    expect(requests.single.method, 'DELETE');
    expect(requests.single.url.path, endsWith('/tv/tracking/t1'));
  });

  test('refresh posts tmdbId', () async {
    final requests = <http.BaseRequest>[];
    await service({}, requests).refresh(1399);
    final request = requests.single;
    expect(request.method, 'POST');
    expect(request.url.path, endsWith('/tv/refresh'));
    expect(jsonDecode((request as http.Request).body), {'tmdbId': 1399});
  });

  test('episodeWatch parses watch list', () async {
    final requests = <http.BaseRequest>[];
    final watch = await service({
      'tvShowEpisodeWatch': [
        {'season': 1, 'episode': 1, 'status': 'Completed'},
        {'season': 1, 'episode': 2, 'status': 'Completed'},
      ],
    }, requests).episodeWatch('u1', 't1');

    final uri = requests.single.url;
    expect(uri.path, endsWith('/tv/episode/watch'));
    expect(uri.queryParameters['userId'], 'u1');
    expect(watch.length, 2);
    expect(watch.first.season, 1);
  });

  test('watchEpisodes posts episode batch with Completed status', () async {
    final requests = <http.BaseRequest>[];
    await service(
      {},
      requests,
    ).watchEpisodes('t1', [(season: 1, episode: 1), (season: 1, episode: 2)]);

    final request = requests.single;
    expect(request.method, 'POST');
    expect(request.url.path, endsWith('/tv/episode/watch'));
    expect(jsonDecode((request as http.Request).body), {
      'tvShowId': 't1',
      'episodes': [
        {'season': 1, 'episode': 1, 'status': 'Completed'},
        {'season': 1, 'episode': 2, 'status': 'Completed'},
      ],
    });
  });

  test('unwatchEpisode sends DELETE with season and episode', () async {
    final requests = <http.BaseRequest>[];
    await service({}, requests).unwatchEpisode('t1', 2, 5);

    final request = requests.single;
    expect(request.method, 'DELETE');
    expect(request.url.path, endsWith('/tv/episode/watch'));
    expect(jsonDecode((request as http.Request).body), {
      'tvShowId': 't1',
      'season': 2,
      'episode': 5,
    });
  });

  test('watchAll and unwatchAll hit episode watch all endpoints', () async {
    final requests = <http.BaseRequest>[];
    await service({}, requests).watchAll('t1');
    await service({}, requests).unwatchAll('t1');

    expect(requests[0].method, 'POST');
    expect(requests[0].url.path, endsWith('/tv/episode/watch/all'));
    expect(jsonDecode((requests[0] as http.Request).body), {'tvShowId': 't1'});
    expect(requests[1].method, 'DELETE');
    expect(requests[1].url.path, endsWith('/tv/episode/watch/all'));
  });

  test('watchProviders sends region and parses groups', () async {
    final requests = <http.BaseRequest>[];
    final providers = await service({
      'watchProviders': {
        'region': 'BR',
        'availableRegions': ['BR', 'US'],
        'link': 'https://www.themoviedb.org/tv/1399/watch?locale=BR',
        'flatrate': [
          {'id': 8, 'name': 'Max', 'logoUrl': 'https://img/max.png'},
        ],
      },
    }, requests).watchProviders(1399, region: 'br');

    final uri = requests.single.url;
    expect(uri.path, endsWith('/tv/detail/1399/watch/provider'));
    expect(uri.queryParameters['region'], 'br');
    expect(providers.offer('flatrate').single.name, 'Max');
  });

  test('watchProviderRegions parses region list', () async {
    final requests = <http.BaseRequest>[];
    final regions = await service({
      'regions': [
        {'code': 'BR', 'name': 'Brazil', 'nativeName': 'Brasil'},
      ],
    }, requests).watchProviderRegions();

    expect(requests.single.url.path, endsWith('/tv/watch/provider/region'));
    expect(regions.single.code, 'BR');
  });
}
