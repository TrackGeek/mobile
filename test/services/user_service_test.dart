import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trackgeek/app/api_config.dart';
import 'package:trackgeek/models/api_exception.dart';
import 'package:trackgeek/services/api_client.dart';
import 'package:trackgeek/services/user_service.dart';

void main() {
  final requests = <http.Request>[];

  UserService service(Object? response, {int status = 200}) {
    final api = ApiClient(
      config: ApiConfig(baseUrl: 'https://api.example.test'),
      client: MockClient((request) async {
        requests.add(request);
        return http.Response.bytes(utf8.encode(jsonEncode(response)), status);
      }),
    );
    addTearDown(api.close);
    return UserService(api);
  }

  setUp(requests.clear);

  test('followStatus reads isFollowing from the envelope', () async {
    final following = await service({
      'followStatus': {'isFollowing': true, 'followsYou': false},
    }).followStatus('ana');
    expect(following, isTrue);
    expect(requests.single.method, 'GET');
    expect(requests.single.url.path, '/user/follow-status/ana');

    final notFollowing = await service({
      'followStatus': {'isFollowing': false, 'followsYou': true},
    }).followStatus('ana');
    expect(notFollowing, isFalse);
  });

  test('followStatus rejects malformed payloads', () async {
    for (final response in [
      <String, dynamic>{},
      {'followStatus': 'yes'},
      {
        'followStatus': {'isFollowing': 'yes'},
      },
    ]) {
      await expectLater(
        service(response).followStatus('ana'),
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

  test('follow and unfollow post to the web endpoints', () async {
    await service(<String, dynamic>{}).follow('u1');
    await service(<String, dynamic>{}).unfollow('u2');
    expect(requests[0].method, 'POST');
    expect(requests[0].url.path, '/user/follow/u1');
    expect(requests[1].method, 'POST');
    expect(requests[1].url.path, '/user/unfollow/u2');
  });
}
