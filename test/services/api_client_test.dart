import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trackgeek/app/api_config.dart';
import 'package:trackgeek/models/api_exception.dart';
import 'package:trackgeek/services/api_client.dart';

void main() {
  ApiClient createClient(
    MockClientHandler handler, {
    Duration timeout = const Duration(seconds: 20),
  }) {
    final api = ApiClient(
      config: ApiConfig(baseUrl: 'https://api.example.test/v1'),
      client: MockClient(handler),
      timeout: timeout,
    );
    addTearDown(api.close);
    return api;
  }

  test(
    'sends language/version and decodes UTF-8 without charset header',
    () async {
      final api = createClient((request) async {
        expect(request.url.path, '/v1/anime/search');
        expect(request.headers['X-TrackGeek-Language'], 'ja-JP');
        expect(request.headers['X-TrackGeek-Version'], '1.0.0');
        expect(request.headers['Accept'], 'application/json');
        expect(request.headers.containsKey('Authorization'), isFalse);
        expect(request.followRedirects, isFalse);
        return http.Response.bytes(utf8.encode('{"title":"呪術廻戦 — ação"}'), 200);
      });

      expect(await api.getJson('anime/search', language: 'ja-JP'), {
        'title': '呪術廻戦 — ação',
      });
    },
  );

  for (final (status, failure) in [
    (401, ApiFailure.unauthorized),
    (403, ApiFailure.forbidden),
    (404, ApiFailure.notFound),
    (409, ApiFailure.conflict),
    (422, ApiFailure.validation),
    (429, ApiFailure.rateLimited),
    (503, ApiFailure.server),
    (302, ApiFailure.http),
  ]) {
    test('classifies HTTP $status before decoding response body', () async {
      var requests = 0;
      final api = createClient((_) async {
        requests++;
        return http.Response('<html>upstream unavailable</html>', status);
      });

      await expectLater(
        api.getJson('anime/search'),
        throwsA(
          isA<ApiException>()
              .having((error) => error.failure, 'failure', failure)
              .having((error) => error.statusCode, 'status', status),
        ),
      );
      expect(requests, 1);
    });
  }

  test(
    'recognizes both server code formats without exposing raw body',
    () async {
      for (final body in ['"UNAUTHORIZED"', '{"code":"UNAUTHORIZED"}']) {
        final api = createClient((_) async => http.Response(body, 401));
        await expectLater(
          api.getJson('anime/search'),
          throwsA(
            isA<ApiException>().having(
              (error) => error.serverCode,
              'serverCode',
              'UNAUTHORIZED',
            ),
          ),
        );
      }
      final api = createClient(
        (_) async => http.Response('{"code":"private diagnostic text"}', 500),
      );
      await expectLater(
        api.getJson('anime/search'),
        throwsA(
          isA<ApiException>().having((e) => e.serverCode, 'code', isNull),
        ),
      );
    },
  );

  test(
    'rejects invalid JSON, UTF-8 and non-object success responses',
    () async {
      for (final body in [
        utf8.encode('not JSON'),
        [255],
        utf8.encode('[]'),
      ]) {
        final api = createClient((_) async => http.Response.bytes(body, 200));
        await expectLater(
          api.getJson('anime/search'),
          throwsA(
            isA<ApiException>().having(
              (error) => error.failure,
              'failure',
              ApiFailure.invalidResponse,
            ),
          ),
        );
      }
    },
  );

  test('normalizes network failures', () async {
    final api = createClient(
      (_) async => throw http.ClientException('private'),
    );
    await expectLater(
      api.getJson('anime/search'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.failure,
          'failure',
          ApiFailure.network,
        ),
      ),
    );
  });

  test('timeout stops waiting and aborts pending request', () async {
    final transport = _PendingClient();
    final api = ApiClient(
      config: ApiConfig(baseUrl: 'https://api.example.test'),
      client: transport,
      timeout: const Duration(milliseconds: 10),
    );
    addTearDown(api.close);

    await expectLater(
      api.getJson('anime/search'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.failure,
          'failure',
          ApiFailure.timeout,
        ),
      ),
    );
    await transport.aborted.future;
  });

  test('caller cancellation aborts pending request', () async {
    final transport = _PendingClient();
    final api = ApiClient(
      config: ApiConfig(baseUrl: 'https://api.example.test'),
      client: transport,
    );
    addTearDown(api.close);
    final cancel = Completer<void>();
    final result = api.getJson('anime/search', cancelWhen: cancel.future);
    final expectation = expectLater(
      result,
      throwsA(
        isA<ApiException>().having(
          (error) => error.failure,
          'failure',
          ApiFailure.cancelled,
        ),
      ),
    );
    cancel.complete();

    await expectation;
    await transport.aborted.future;
  });
}

class _PendingClient extends http.BaseClient {
  final aborted = Completer<void>();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    await (request as http.AbortableRequest).abortTrigger;
    aborted.complete();
    throw http.RequestAbortedException(request.url);
  }
}
