import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trackgeek/app/api_config.dart';
import 'package:trackgeek/components/media/progress_card.dart';
import 'package:trackgeek/l10n/l10n_context.dart';
import 'package:trackgeek/models/media_type.dart';
import 'package:trackgeek/models/progress_item.dart';
import 'package:trackgeek/services/api_client.dart';
import 'package:trackgeek/services/progress_service.dart';

import 'helpers/test_l10n.dart';

void main() {
  testWidgets(
    'cover shows year and unknown total; plus does not navigate or submit twice',
    (tester) async {
      final response = Completer<http.Response>();
      var calls = 0;
      var navigations = 0;
      final service = ProgressService(
        ApiClient(
          config: ApiConfig(baseUrl: 'https://api.example.test'),
          client: MockClient((_) {
            calls++;
            return response.future;
          }),
        ),
      );
      final l10n = await testL10n();
      await tester.pumpWidget(
        L10nScope(
          localizations: l10n,
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 130,
                child: ProgressCard(
                  item: const ProgressItem(
                    type: MediaType.manga,
                    detailId: '20',
                    mediaId: 'internal',
                    title: 'Example',
                    status: 'Reading',
                    year: 2026,
                    current: 2,
                  ),
                  progress: service,
                  onTap: () => navigations++,
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('2026'), findsOneWidget);
      expect(find.text('2/?'), findsOneWidget);
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      await tester.tap(find.byType(IconButton));
      expect(calls, 1);
      expect(navigations, 0);
      response.complete(http.Response('{}', 500));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('2/?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
