import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trackgeek/app/api_config.dart';
import 'package:trackgeek/components/media/progress_card.dart';
import 'package:trackgeek/components/user/progress_tab.dart';
import 'package:trackgeek/controllers/session_controller.dart';
import 'package:trackgeek/l10n/l10n_context.dart';
import 'package:trackgeek/models/media_type.dart';
import 'package:trackgeek/services/api_client.dart';
import 'package:trackgeek/services/auth_service.dart';
import 'package:trackgeek/services/progress_service.dart';

import '../helpers/test_l10n.dart';

void main() {
  testWidgets(
    'progress grid uses compact cards and refreshes after increment',
    (tester) async {
      var chaptersRead = 2;
      var progressLoads = 0;
      final api = ApiClient(
        config: ApiConfig(baseUrl: 'https://api.example.test'),
        client: MockClient((request) async {
          if (request.url.path.endsWith('/manga/progress/filters')) {
            return http.Response(jsonEncode({'filters': {}}), 200);
          }
          if (request.method == 'POST' &&
              request.url.path.endsWith('/manga/progress')) {
            chaptersRead++;
            return http.Response('{}', 200);
          }
          if (request.method == 'GET' &&
              request.url.path.endsWith('/manga/progress/')) {
            progressLoads++;
            return http.Response(
              jsonEncode({
                'mangaProgresses': {
                  'items': [
                    {
                      'status': 'Reading',
                      'chaptersRead': chaptersRead,
                      'manga': {
                        'id': 'internal',
                        'anilistId': 20,
                        'title': 'Example',
                        'year': 2026,
                        'numberOfChapters': 10,
                      },
                    },
                  ],
                  'total': 1,
                  'pages': 1,
                  'inPage': 1,
                  'itemsInPage': 1,
                  'itemsPerPage': 20,
                },
              }),
              200,
            );
          }
          return http.Response('{}', 404);
        }),
      );
      addTearDown(api.close);
      final progress = ProgressService(api);
      addTearDown(progress.dispose);
      final session = SessionController(AuthService(api));
      addTearDown(session.dispose);
      final l10n = await testL10n();

      await tester.pumpWidget(
        L10nScope(
          localizations: l10n,
          child: MaterialApp(
            home: Scaffold(
              body: UserProgressTab(
                userId: 'user',
                session: session,
                progress: progress,
                contentType: MediaType.manga,
                onContentTypeChange: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProgressCard), findsOneWidget);
      expect(find.text('2026'), findsOneWidget);
      expect(find.text('2/10'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);

      await tester.tap(
        find.descendant(
          of: find.byType(ProgressCard),
          matching: find.byType(IconButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(progressLoads, 2);
      expect(find.text('3/10'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
