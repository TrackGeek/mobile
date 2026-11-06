import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trackgeek/app/api_config.dart';
import 'package:trackgeek/l10n/l10n_context.dart';
import 'package:trackgeek/pages/notifications_page.dart';
import 'package:trackgeek/services/api_client.dart';
import 'package:trackgeek/services/notification_service.dart';

import '../helpers/test_l10n.dart';

void main() {
  testWidgets('updates unread count after individual and bulk read actions', (
    tester,
  ) async {
    var unread = 3;
    var unreadCountRequests = 0;
    final read = <String>{};
    final api = ApiClient(
      config: ApiConfig(baseUrl: 'https://api.example.test'),
      client: MockClient((request) async {
        final path = request.url.path;
        if (path == '/notifications/unread/count') {
          unreadCountRequests++;
          return http.Response(jsonEncode({'count': unread}), 200);
        }
        if (path == '/notifications/n1/read' && request.method == 'POST') {
          read.add('n1');
          unread--;
          return http.Response('{}', 200);
        }
        if (path == '/notifications/read/all' && request.method == 'POST') {
          read.addAll(['n1', 'n2', 'n3']);
          unread = 0;
          return http.Response('{}', 200);
        }
        if (path == '/notifications') {
          return http.Response(
            jsonEncode({
              'notifications': {
                'items': [
                  for (final id in ['n1', 'n2', 'n3'])
                    {
                      'id': id,
                      'type': 'CommentOnProfile',
                      'readAt': read.contains(id)
                          ? '2026-11-06T10:01:00Z'
                          : null,
                      'createdAt': '2026-11-06T10:00:00Z',
                      'actor': {
                        'id': 'u1',
                        'name': 'Ana',
                        'username': 'ana',
                      },
                    },
                ],
                'total': 3,
                'pages': 1,
                'inPage': 1,
                'itemsInPage': 3,
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
    final l10n = await testL10n();
    final counts = <int>[];

    await tester.pumpWidget(
      L10nScope(
        localizations: l10n,
        child: MaterialApp(
          home: NotificationsPage(
            notifications: NotificationService(api),
            onUnreadChanged: counts.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(counts.last, 3);

    await tester.tap(find.byTooltip('notifications:markAsRead').first);
    await tester.pumpAndSettle();
    expect(counts.last, 2);

    await tester.tap(find.byTooltip('notifications:markAllAsRead'));
    await tester.pumpAndSettle();
    expect(counts.last, 0);
    expect(unreadCountRequests, 3);
  });
}
