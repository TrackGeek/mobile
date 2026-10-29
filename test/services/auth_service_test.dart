import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trackgeek/app/api_config.dart';
import 'package:trackgeek/models/api_exception.dart';
import 'package:trackgeek/services/api_client.dart';
import 'package:trackgeek/services/auth_service.dart';

void main() {
  AuthService createService(MockClientHandler handler) {
    final api = ApiClient(
      config: ApiConfig(baseUrl: 'https://api.example.test'),
      client: MockClient(handler),
    );
    addTearDown(api.close);
    return AuthService(api);
  }

  const sessionCookie =
      'better-auth.session_token=tok.sig; Path=/; HttpOnly; Secure';

  test('socialAuthorizationUrl posts provider with app callback and captures state cookie', () async {
    final service = createService((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/auth/sign-in/social');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['provider'], 'discord');
      expect(body['callbackURL'], 'trackgeek://auth/callback');
      expect(body['errorCallbackURL'], 'trackgeek://auth/callback');
      expect(body['disableRedirect'], true);
      return http.Response(
        '{"url":"https://discord.com/oauth2/authorize?x=1","redirect":false}',
        200,
        headers: {'set-cookie': 'better-auth.state=abc.sig; Path=/; HttpOnly'},
      );
    });

    final start = await service.socialAuthorizationUrl('discord');
    expect(start.provider, 'discord');
    expect(start.authorizationUrl.host, 'discord.com');
    expect(start.stateCookieName, 'better-auth.state');
    expect(start.stateCookieValue, 'abc.sig');
  });

  test('socialAuthorizationUrl rejects a response without url', () async {
    final service = createService(
      (_) async => http.Response('{"redirect":true}', 200),
    );
    await expectLater(
      service.socialAuthorizationUrl('github'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.failure,
          'failure',
          ApiFailure.invalidResponse,
        ),
      ),
    );
  });

  test('signInWithIdToken posts idToken and adopts returned token', () async {
    final service = createService((request) async {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['provider'], 'google');
      expect(body['idToken'], {'token': 'idtok', 'accessToken': 'acctok'});
      return http.Response(
        '{"redirect":false,"token":"sess1","user":{"id":"u1","name":"N","email":"e@x.y"}}',
        200,
      );
    });

    final result = await service.signInWithIdToken(
      'google',
      token: 'idtok',
      accessToken: 'acctok',
    );
    expect(result.user?.id, 'u1');
    expect(service.token, 'sess1');
  });

  test(
    'applySessionCookie sends cookie and trusted origin on get-session',
    () async {
      final service = createService((request) async {
        expect(request.url.path, '/auth/get-session');
        expect(
          request.headers['Cookie'],
          contains('better-auth.session_token=tok.sig'),
        );
        expect(request.headers['Origin'], 'trackgeek://auth/callback');
        return http.Response(
          '{"user":{"id":"u2","name":"M","email":"m@x.y"},"session":{}}',
          200,
        );
      });

      final result = await service.applySessionCookie('tok.sig');
      expect(result.user?.id, 'u2');
    },
  );

  test('applyAuthCallback parses cookie param from deep link', () async {
    var calls = 0;
    final service = createService((request) async {
      calls++;
      expect(request.headers['Cookie'], contains('session_token'));
      return http.Response(
        '{"user":{"id":"u3","name":"X","email":"x@x.y"}}',
        200,
      );
    });

    final result = await service.applyAuthCallback(
      Uri.parse(
        'trackgeek://auth/callback?cookie=${Uri.encodeComponent(sessionCookie)}',
      ),
    );
    expect(result?.user?.id, 'u3');
    expect(calls, 1);
  });

  test(
    'applyAuthCallback ignores foreign schemes and missing cookie',
    () async {
      final service = createService(
        (_) async => http.Response('{"user":{"id":"u"}}', 200),
      );
      expect(
        await service.applyAuthCallback(
          Uri.parse('https://evil.test/?cookie=x'),
        ),
        isNull,
      );
      expect(
        await service.applyAuthCallback(Uri.parse('trackgeek://auth/callback')),
        isNull,
      );
    },
  );

  test('sendMagicLink posts email with app callback', () async {
    final service = createService((request) async {
      expect(request.url.path, '/auth/sign-in/magic-link');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['email'], 'a@b.c');
      expect(body['callbackURL'], 'trackgeek://auth/callback');
      return http.Response('{"status":true}', 200);
    });

    await service.sendMagicLink('a@b.c');
  });

  test('sendMagicLink rejects status false', () async {
    final service = createService(
      (_) async => http.Response('{"status":false}', 200),
    );
    await expectLater(
      service.sendMagicLink('a@b.c'),
      throwsA(isA<ApiException>()),
    );
  });

  test(
    'passkey options and verification keep challenge cookie and return user',
    () async {
      var verifyCookie = '';
      final service = createService((request) async {
        if (request.url.path == '/auth/passkey/generate-authenticate-options') {
          return http.Response(
            '{"challenge":"chg","rpId":"trackgeek.net","timeout":60000}',
            200,
            headers: {
              'set-cookie': 'better-auth-passkey=pktok.sig; Path=/; HttpOnly',
            },
          );
        }
        if (request.url.path == '/auth/passkey/verify-authentication') {
          verifyCookie = request.headers['Cookie'] ?? '';
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['response'], {'id': 'cred1'});
          return http.Response(
            '{"user":{"id":"u4","name":"P","email":"p@x.y"},"session":{"token":"t"}}',
            200,
            headers: {'set-auth-token': 'fresh'},
          );
        }
        return http.Response('{}', 404);
      });

      final options = await service.passkeyAuthenticateOptions();
      expect(options['challenge'], 'chg');
      final result = await service.verifyPasskey({'id': 'cred1'});
      expect(verifyCookie, contains('better-auth-passkey=pktok.sig'));
      expect(verifyCookie, isNot(contains('session_token')));
      expect(result.user?.id, 'u4');
      expect(service.token, 'fresh');
    },
  );
}
