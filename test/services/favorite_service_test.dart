import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trackgeek/app/api_config.dart';
import 'package:trackgeek/models/api_exception.dart';
import 'package:trackgeek/services/api_client.dart';
import 'package:trackgeek/services/favorite_service.dart';

void main() {
  FavoriteService service(
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
    return FavoriteService(api);
  }

  test('status sends type and personId as query params', () async {
    final requests = <http.BaseRequest>[];
    final favorited = await service({
      'favorited': true,
    }, requests).status(FavoriteTarget.person, 'p1');

    expect(favorited, isTrue);
    final uri = requests.single.url;
    expect(uri.path, endsWith('/favorite/status'));
    expect(uri.queryParameters['type'], 'Person');
    expect(uri.queryParameters['personId'], 'p1');
  });

  test(
    'toggle posts body when unfavorited and deletes when favorited',
    () async {
      final requests = <http.BaseRequest>[];
      final fav = service({}, requests);

      await fav.toggle(FavoriteTarget.person, 'p1', false);
      expect(requests.last.method, 'POST');
      expect(requests.last.url.path, endsWith('/favorite'));
      expect(jsonDecode((requests.last as http.Request).body), {
        'type': 'Person',
        'personId': 'p1',
      });

      await fav.toggle(FavoriteTarget.person, 'p1', true);
      expect(requests.last.method, 'DELETE');
      expect(jsonDecode((requests.last as http.Request).body), {
        'type': 'Person',
        'personId': 'p1',
      });
    },
  );

  test('uses media id fields for other targets', () async {
    final requests = <http.BaseRequest>[];
    final fav = service({'favorited': false}, requests);
    await fav.status(FavoriteTarget.movie, '603');
    expect(requests.single.url.queryParameters['movieId'], '603');
    expect(requests.single.url.queryParameters['type'], 'Movie');
  });

  test('rejects malformed status response', () async {
    await expectLater(
      service({}, []).status(FavoriteTarget.person, 'p1'),
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
