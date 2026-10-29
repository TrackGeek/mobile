import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trackgeek/app/api_config.dart';
import 'package:trackgeek/models/api_exception.dart';
import 'package:trackgeek/models/media_type.dart';
import 'package:trackgeek/services/api_client.dart';
import 'package:trackgeek/services/media_detail_service.dart';

void main() {
  MediaDetailService service(Map<String, dynamic> response) {
    final api = ApiClient(
      config: ApiConfig(baseUrl: 'https://api.example.test'),
      client: MockClient(
        (_) async =>
            http.Response.bytes(utf8.encode(jsonEncode(response)), 200),
      ),
    );
    addTearDown(api.close);
    return MediaDetailService(api);
  }

  test('maps anime detail envelope', () async {
    final detail = await service({
      'anime': {
        'id': 'a1',
        'malId': 20,
        'title': 'Naruto',
        'titles': [
          {'type': 'Default', 'title': 'Naruto'},
          {'type': 'Japanese', 'title': 'ナルト'},
        ],
        'imageUrl': 'https://x.test/n.jpg',
        'type': 'TV',
        'status': 'Finished Airing',
        'numberOfEpisodes': 220,
        'isAdult': false,
        'synopsis': 'Ninja.',
        'genres': ['Action'],
        'studios': [
          {'name': 'Studio Pierrot'},
        ],
        'malReviewScore': 8.02,
      },
    }).detail(MediaType.anime, '20');
    expect(detail.title, 'Naruto');
    expect(detail.altTitle, 'ナルト');
    expect(detail.score, 8.02);
    expect(detail.chips, contains('Action'));
    expect(detail.fields.any((f) => f.labelKey == 'common:studio'), isTrue);
  });

  test('maps tv envelope key and fields', () async {
    final detail = await service({
      'tvShow': {
        'id': 't1',
        'tmdbId': 7,
        'name': 'Show',
        'posterUrl': 'https://x.test/p.jpg',
        'status': 'Returning Series',
        'numberOfSeasons': 3,
        'numberOfEpisodes': 30,
        'isAdult': false,
        'genres': [
          {'name': 'Drama'},
        ],
        'tmdbReviewScore': 8.4,
      },
    }).detail(MediaType.tv, '7');
    expect(detail.title, 'Show');
    expect(detail.fields.any((f) => f.labelKey == 'common:seasons'), isTrue);
  });

  test('maps game fields', () async {
    final detail = await service({
      'game': {
        'id': 'g1',
        'igdbId': 1020,
        'name': 'GTA V',
        'coverUrl': 'https://x.test/c.jpg',
        'gameStatus': 'Released',
        'summary': 'Crime.',
        'igdbReviewScore': 88.8,
        'genres': [
          {'name': 'Shooter'},
        ],
        'involvedCompanies': [
          {'companyName': 'Rockstar North', 'developer': true},
        ],
      },
    }).detail(MediaType.game, '1020');
    expect(detail.title, 'GTA V');
    expect(
      detail.fields.any(
        (f) => f.labelKey == 'common:developer' && f.value == 'Rockstar North',
      ),
      isTrue,
    );
  });

  test('rejects malformed payloads', () async {
    for (final response in [
      <String, dynamic>{},
      {'anime': <String, dynamic>{}},
      {'anime': 'invalid'},
    ]) {
      await expectLater(
        service(response).detail(MediaType.anime, '20'),
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
