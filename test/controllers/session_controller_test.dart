import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackgeek/app/api_config.dart';
import 'package:trackgeek/controllers/session_controller.dart';
import 'package:trackgeek/l10n/trackgeek_localizations.dart';
import 'package:trackgeek/services/api_client.dart';
import 'package:trackgeek/services/auth_service.dart';

Future<String> _read(String path) async {
  if (path.endsWith('common.json')) {
    final language = RegExp(r'i18n/([^/]+)/').firstMatch(path)?[1];
    return '{"language":"$language"}';
  }
  return '{}';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('applies the account language after sign in', () async {
    SharedPreferences.setMockInitialValues({});
    final api = ApiClient(
      config: ApiConfig(baseUrl: 'https://api.example.test'),
      client: MockClient((request) async {
        expect(request.url.path, '/auth/sign-in/email');
        return http.Response(
          '{"user":{"id":"u1","name":"User","email":"u@example.test",'
          '"profile":{"language":"pt-BR"}}}',
          200,
          headers: {'set-auth-token': 'token'},
        );
      }),
    );
    addTearDown(api.close);
    final l10n = await TrackGeekLocalizations.load(
      const Locale('en', 'US'),
      read: _read,
    );
    addTearDown(l10n.dispose);
    final session = SessionController(AuthService(api), localizations: l10n);
    addTearDown(session.dispose);

    expect(await session.signIn('u@example.test', 'password'), isTrue);

    expect(l10n.language, 'pt-BR');
    expect(l10n.locale, const Locale('pt', 'BR'));
  });

  test('restores, refreshes and clears the account language', () async {
    SharedPreferences.setMockInitialValues({
      SessionController.tokenKey: 'token',
    });
    var language = 'pt-PT';
    final api = ApiClient(
      config: ApiConfig(baseUrl: 'https://api.example.test'),
      client: MockClient((request) async {
        if (request.url.path == '/auth/get-session') {
          return http.Response(
            '{"user":{"id":"u1","name":"User","email":"u@example.test",'
            '"profile":{"language":"$language"}}}',
            200,
          );
        }
        if (request.url.path == '/auth/sign-out') {
          return http.Response('{}', 200);
        }
        return http.Response('{}', 404);
      }),
    );
    addTearDown(api.close);
    final l10n = await TrackGeekLocalizations.load(
      const Locale('en', 'US'),
      read: _read,
    );
    addTearDown(l10n.dispose);
    final session = SessionController(AuthService(api), localizations: l10n);
    addTearDown(session.dispose);

    await session.restore();

    expect(session.user?.language, 'pt-PT');
    expect(l10n.language, 'pt-PT');
    expect(l10n.locale, const Locale('pt', 'PT'));

    language = 'fr-FR';
    await session.refresh();

    expect(l10n.language, 'fr-FR');
    expect(l10n.locale, const Locale('fr', 'FR'));

    await session.signOut();

    expect(session.user, isNull);
    expect(l10n.language, 'en-US');
  });
}
