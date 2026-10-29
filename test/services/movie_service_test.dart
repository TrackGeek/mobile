import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trackgeek/app/api_config.dart';
import 'package:trackgeek/models/api_exception.dart';
import 'package:trackgeek/services/api_client.dart';
import 'package:trackgeek/services/movie_service.dart';

void main() {
  MovieService service(
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
    return MovieService(api);
  }

  final detailResponse = {
    'movie': {
      'id': 'movie-uuid',
      'tmdbId': 550,
      'imdbId': 'tt0137523',
      'isAdult': false,
      'tmdbReviewScore': 8.4,
      'budget': '63000000',
      'revenue': '100853753',
      'backdropUrl': 'https://img/backdrop.jpg',
      'belongsToCollection': {'id': 948, 'name': 'Fight Club Collection'},
      'homepage': 'https://example.com/fight-club',
      'originalLanguage': 'en',
      'originalTitle': 'Fight Club',
      'overview': 'A ticking-Loss insomnia',
      'genres': ['Drama', 'Thriller'],
      'popularity': 61.4,
      'posterUrl': 'https://img/poster.jpg',
      'productionCompanies': [
        {
          'id': 508,
          'name': 'Regency Enterprises',
          'logoUrl': 'https://img/logo.png',
          'originCountry': 'US',
        },
      ],
      'productionCountries': ['United States of America'],
      'releaseDate': '1999-10-15T00:00:00.000Z',
      'runtime': 139,
      'spokenLanguages': [
        {'englishName': 'English', 'name': 'English', 'iso639_1': 'en'},
      ],
      'status': 'Released',
      'title': 'Fight Club',
      'cast': [
        {
          'id': 819,
          'name': 'Edward Norton',
          'character': 'Narrator',
          'profileUrl': 'https://img/norton.jpg',
          'slug': 'edward-norton',
        },
      ],
      'crew': [
        {
          'id': 7467,
          'name': 'David Fincher',
          'job': 'Director',
          'profileUrl': 'https://img/fincher.jpg',
          'slug': 'david-fincher',
        },
      ],
      'trailerId': 'qtRKdVHc-cE',
      'external': {'instagram_id': 'fightclub', 'twitter_id': 'fightclub'},
      'backdrops': ['https://img/b1.jpg', 'https://img/b2.jpg'],
      'lastRefreshedAt': '2024-01-01T00:00:00.000Z',
      'tgReviewScore': 4.6,
      'progressStats': {
        'planToWatch': {'count': 10, 'percentage': 50.0},
        'watching': {'count': 4, 'percentage': 20.0},
        'completed': {'count': 5, 'percentage': 25.0},
        'dropped': {'count': 1, 'percentage': 5.0},
      },
    },
  };

  test(
    'detail calls movie/detail/tmdbId and parses the movie envelope',
    () async {
      final requests = <http.BaseRequest>[];
      final movie = await service(detailResponse, requests).detail(550);

      expect(requests.single.url.path, endsWith('/movie/detail/550'));
      expect(movie.id, 'movie-uuid');
      expect(movie.tmdbId, 550);
      expect(movie.imdbId, 'tt0137523');
      expect(movie.title, 'Fight Club');
      expect(movie.budget, 63000000);
      expect(movie.revenue, 100853753);
      expect(movie.genres, ['Drama', 'Thriller']);
      expect(movie.belongsToCollection?.id, 948);
      expect(movie.productionCompanies.single.name, 'Regency Enterprises');
      expect(movie.spokenLanguages.single.iso6391, 'en');
      expect(movie.cast.single.character, 'Narrator');
      expect(movie.directors.single.name, 'David Fincher');
      expect(movie.trailerId, 'qtRKdVHc-cE');
      expect(movie.external?['instagram_id'], 'fightclub');
      expect(movie.backdrops.length, 2);
      expect(movie.tgReviewScore, 4.6);
      expect(movie.progressStats?.planToWatch.count, 10);
      expect(movie.progressStats?.paused.count, 0);
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

  test('franchise calls movie/franchise/slug and parses parts', () async {
    final requests = <http.BaseRequest>[];
    final franchise = await service({
      'franchise': {
        'id': 948,
        'name': 'Fight Club Collection',
        'slug': 'fight-club-collection',
        'overview': 'Movies about soap',
        'posterUrl': 'https://img/p.jpg',
        'backdropUrl': 'https://img/b.jpg',
        'parts': [
          {
            'tmdbId': 550,
            'title': 'Fight Club',
            'isAdult': false,
            'overview': 'o',
            'releaseDate': '1999-10-15',
            'posterUrl': 'https://img/poster.jpg',
            'tmdbReviewScore': 8.4,
            'tgReviewScore': 4.6,
          },
        ],
      },
    }, requests).franchise('948-fight-club-collection');

    expect(
      requests.single.url.path,
      endsWith('/movie/franchise/948-fight-club-collection'),
    );
    expect(franchise.name, 'Fight Club Collection');
    expect(franchise.parts.single.tmdbId, 550);
    expect(franchise.parts.single.tgReviewScore, 4.6);
  });

  test('progress sends userId and movieId query params', () async {
    final requests = <http.BaseRequest>[];
    final progress = await service({
      'movieProgresses': {
        'items': [
          {
            'id': 'p1',
            'status': 'Completed',
            'watchCount': 3,
            'startedAt': '2024-01-01T00:00:00.000Z',
            'completedAt': '2024-02-01T00:00:00.000Z',
          },
        ],
      },
    }, requests).progress('u1', 'm1');

    final uri = requests.single.url;
    expect(uri.path, endsWith('/movie/progress'));
    expect(uri.queryParameters['userId'], 'u1');
    expect(uri.queryParameters['movieId'], 'm1');
    expect(progress?.id, 'p1');
    expect(progress?.status, 'Completed');
    expect(progress?.watchCount, 3);
  });

  test('progress returns null for empty list', () async {
    final progress = await service({
      'movieProgresses': {'items': <dynamic>[]},
    }, []).progress('u1', 'm1');
    expect(progress, isNull);
  });

  test('saveProgress posts movieId, status and watchCount', () async {
    final requests = <http.BaseRequest>[];
    await service(
      {},
      requests,
    ).saveProgress('m1', status: 'Completed', watchCount: 2);

    final request = requests.single;
    expect(request.method, 'POST');
    expect(request.url.path, endsWith('/movie/progress'));
    expect(jsonDecode((request as http.Request).body), {
      'movieId': 'm1',
      'status': 'Completed',
      'watchCount': 2,
    });
  });

  test('saveProgress omits null watchCount', () async {
    final requests = <http.BaseRequest>[];
    await service({}, requests).saveProgress('m1', status: 'Planning');

    expect(jsonDecode((requests.single as http.Request).body), {
      'movieId': 'm1',
      'status': 'Planning',
    });
  });

  test('deleteProgress calls DELETE movie/progress/id', () async {
    final requests = <http.BaseRequest>[];
    await service({}, requests).deleteProgress('p1');
    expect(requests.single.method, 'DELETE');
    expect(requests.single.url.path, endsWith('/movie/progress/p1'));
  });

  test('refresh posts movie id', () async {
    final requests = <http.BaseRequest>[];
    await service({}, requests).refresh(550);
    final request = requests.single;
    expect(request.method, 'POST');
    expect(request.url.path, endsWith('/movie/refresh'));
    expect(jsonDecode((request as http.Request).body), {'id': 550});
  });

  test('watchProviders sends region query and parses offer groups', () async {
    final requests = <http.BaseRequest>[];
    final providers = await service({
      'watchProviders': {
        'region': 'BR',
        'availableRegions': ['BR', 'US'],
        'link': 'https://www.themoviedb.org/movie/550/watch?locale=BR',
        'flatrate': [
          {'id': 8, 'name': 'Netflix', 'logoUrl': 'https://img/netflix.png'},
        ],
        'rent': [
          {'id': 2, 'name': 'Apple TV', 'logoUrl': 'https://img/apple.png'},
        ],
      },
    }, requests).watchProviders(550, region: 'br');

    final uri = requests.single.url;
    expect(uri.path, endsWith('/movie/detail/550/watch/provider'));
    expect(uri.queryParameters['region'], 'br');
    expect(providers.region, 'BR');
    expect(providers.availableRegions, ['BR', 'US']);
    expect(providers.offer('flatrate').single.name, 'Netflix');
    expect(providers.offer('rent').single.name, 'Apple TV');
    expect(providers.offer('free'), isEmpty);
    expect(providers.link, contains('themoviedb.org'));
  });

  test('watchProviders rejects malformed response', () async {
    await expectLater(
      service({}, []).watchProviders(1, region: 'US'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.failure,
          'failure',
          ApiFailure.invalidResponse,
        ),
      ),
    );
  });

  test('watchProviderRegions parses region list', () async {
    final requests = <http.BaseRequest>[];
    final regions = await service({
      'regions': [
        {'code': 'BR', 'name': 'Brazil', 'nativeName': 'Brasil'},
        {'code': 'US', 'name': 'United States', 'nativeName': ''},
      ],
    }, requests).watchProviderRegions();

    expect(requests.single.url.path, endsWith('/movie/watch/provider/region'));
    expect(regions.first.code, 'BR');
    expect(regions.first.name, 'Brazil');
    expect(regions.first.nativeName, 'Brasil');
  });

  test('watchProviderRegions rejects malformed response', () async {
    await expectLater(
      service({}, []).watchProviderRegions(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.failure,
          'failure',
          ApiFailure.invalidResponse,
        ),
      ),
    );
  });
}
