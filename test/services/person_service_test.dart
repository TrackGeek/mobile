import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trackgeek/app/api_config.dart';
import 'package:trackgeek/models/api_exception.dart';
import 'package:trackgeek/models/media_type.dart';
import 'package:trackgeek/models/person.dart';
import 'package:trackgeek/services/api_client.dart';
import 'package:trackgeek/services/person_service.dart';

void main() {
  PersonService service(
    Map<String, dynamic> response, {
    List<http.BaseRequest>? requests,
  }) {
    final api = ApiClient(
      config: ApiConfig(baseUrl: 'https://api.example.test'),
      client: MockClient((request) async {
        requests?.add(request);
        return http.Response.bytes(utf8.encode(jsonEncode(response)), 200);
      }),
    );
    addTearDown(api.close);
    return PersonService(api);
  }

  Map<String, dynamic> personJson({
    List<Map<String, dynamic>> credits = const [],
  }) => {
    'person': {
      'id': 'p1',
      'slug': 'keanu-reeves',
      'name': 'Keanu Reeves',
      'tmdbId': 6384,
      'malId': null,
      'anilistId': null,
      'imageUrl': 'https://img.test/k.jpg',
      'biography': 'Actor.',
      'birthday': '1964-09-02T00:00:00.000Z',
      'deathday': null,
      'placeOfBirth': 'Beirut, Lebanon',
      'knownForDepartment': 'Acting',
      'alsoKnownAs': ['Киану Ривз'],
      'gender': 2,
      'homepage': null,
      'popularity': 45.2,
      'images': [],
      'external': {'imdb_id': 'nm0000206'},
      'source': 'tmdb',
      'credits': credits,
      'stats': {
        'total': credits.length,
        'movies': 1,
        'tvShows': 0,
        'anime': 0,
        'manga': 0,
        'tracked': 0,
      },
    },
  };

  test('fetches person by slug and maps fields', () async {
    final requests = <http.BaseRequest>[];
    final person = await service(
      personJson(
        credits: [
          {
            'key': 'movie:603',
            'mediaType': 'movie',
            'id': 603,
            'title': 'The Matrix',
            'imageUrl': 'https://img.test/m.jpg',
            'backdropUrl': 'https://img.test/b.jpg',
            'releaseDate': '1999-03-31T00:00:00.000Z',
            'year': 1999,
            'roles': ['Neo'],
            'isCast': true,
            'isAdult': false,
            'episodeCount': null,
            'externalReviewScore': 8.7,
            'popularity': 90.0,
            'tgReviewScore': 4.8,
            'isTracked': true,
          },
        ],
      ),
      requests: requests,
    ).person('keanu-reeves');

    expect(requests.single.url.path, endsWith('/person/keanu-reeves'));
    expect(person.slug, 'keanu-reeves');
    expect(person.source, PersonSource.tmdb);
    expect(person.alsoKnownAs, ['Киану Ривз']);
    expect(person.external, {'imdb_id': 'nm0000206'});
    expect(person.stats.total, 1);

    final credit = person.credits.single;
    expect(credit.mediaType, MediaType.movie);
    expect(credit.id, 603);
    expect(credit.roles, ['Neo']);
    expect(credit.isCast, isTrue);
    expect(credit.tgReviewScore, 4.8);
    expect(credit.isTracked, isTrue);
  });

  test('fetches manga cast by anilist id', () async {
    final requests = <http.BaseRequest>[];
    await service(personJson(), requests: requests).mangaCast('105167');
    expect(requests.single.url.path, endsWith('/manga/cast/105167'));
  });

  test('rejects malformed person payloads', () async {
    for (final response in [
      <String, dynamic>{},
      {'person': <String, dynamic>{}},
      {'person': 'nope'},
    ]) {
      await expectLater(
        service(response).person('x'),
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
