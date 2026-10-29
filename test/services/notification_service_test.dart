import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trackgeek/app/api_config.dart';
import 'package:trackgeek/models/api_exception.dart';
import 'package:trackgeek/models/media_type.dart';
import 'package:trackgeek/services/api_client.dart';
import 'package:trackgeek/services/notification_service.dart';

void main() {
  NotificationService service(
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
    return NotificationService(api);
  }

  Map<String, dynamic> notification({
    String id = 'n1',
    String type = 'CommentOnProfile',
    String? readAt,
  }) => {
    'id': id,
    'type': type,
    'recipientId': 'u1',
    'actorId': 'u2',
    'metadata': null,
    'readAt': readAt,
    'createdAt': '2026-10-28T10:00:00Z',
    'actor': {
      'id': 'u2',
      'name': 'Ana',
      'username': 'ana',
      'profile': {'id': 'p2', 'avatarUrl': 'https://img.test/a.png'},
    },
    'comment': {'id': 'c1', 'type': 'Profile', 'content': 'hey'},
    'reaction': {'id': 'r1', 'type': 'Comment', 'emoji': '👍'},
    'releaseEvent': null,
  };

  Map<String, dynamic> pageResponse(List<dynamic> items) => {
    'notifications': {
      'items': items,
      'total': items.length,
      'pages': 1,
      'inPage': 1,
      'itemsInPage': items.length,
      'itemsPerPage': 20,
    },
  };

  test('lists notifications with pagination params', () async {
    final requests = <http.BaseRequest>[];
    final page = await service(
      pageResponse([notification()]),
      requests,
    ).notifications(page: 2, itemsPerPage: 20);

    final request = requests.single;
    expect(request.method, 'GET');
    expect(request.url.path, '/notifications');
    expect(request.url.queryParameters['page'], '2');
    expect(request.url.queryParameters['itemsPerPage'], '20');
    expect(page.total, 1);
    final item = page.items.single;
    expect(item.type, 'CommentOnProfile');
    expect(item.isRead, isFalse);
    expect(item.actor?.username, 'ana');
    expect(item.actor?.avatarUrl, 'https://img.test/a.png');
    expect(item.comment?.content, 'hey');
    expect(item.reaction?.emoji, '👍');
    expect(item.isSystem, isFalse);
  });

  test('system types map isSystem', () async {
    for (final type in ['System', 'LevelUp', 'MissionCompleted']) {
      final page = await service(
        pageResponse([notification(type: type)]),
        <http.BaseRequest>[],
      ).notifications();
      expect(page.items.single.isSystem, isTrue, reason: type);
    }
    final page = await service(
      pageResponse([notification(type: 'ReactionOnComment')]),
      <http.BaseRequest>[],
    ).notifications();
    expect(page.items.single.isSystem, isFalse);
  });

  test('parses release event media refs and detail targets', () async {
    Map<String, dynamic> event(Map<String, dynamic> media) => {
      'id': 'e1',
      'type': 'NewEpisodeReleased',
      'mediaType': 'TvShow',
      'title': 'Fallback title',
      'unitTitle': 'Pilot',
      'unitNumber': 3,
      'containerNumber': 2,
      'releaseAt': '2026-10-27T00:00:00Z',
      'anime': null,
      'manga': null,
      'tvShow': null,
      'game': null,
      ...media,
    };

    final requests = <http.BaseRequest>[];
    final page = await service(
      pageResponse([
        {
          ...notification(type: 'NewEpisodeReleased', readAt: 'x'),
          'releaseEvent': event({
            'tvShow': {
              'id': 'uuid-tv',
              'tmdbId': 1399,
              'name': 'GoT',
              'posterUrl': 'https://img.test/p.jpg',
            },
          }),
        },
      ]),
      requests,
    ).notifications();

    final event2 = page.items.single.releaseEvent!;
    expect(event2.detailType, MediaType.tv);
    expect(event2.media?.title, 'GoT');
    expect(event2.media?.detailId, '1399');
    expect(event2.media?.coverUrl, 'https://img.test/p.jpg');
    expect(event2.unitNumber, 3);
    expect(event2.containerNumber, 2);
    expect(page.items.single.isRead, isTrue);
  });

  test('manga prefers anilistId over malId for detail id', () async {
    final page = await service(
      pageResponse([
        {
          ...notification(type: 'NewChapterReleased'),
          'releaseEvent': {
            'id': 'e2',
            'type': 'NewChapterReleased',
            'mediaType': 'Manga',
            'title': 'M',
            'unitTitle': null,
            'unitNumber': 10,
            'containerNumber': null,
            'releaseAt': '2026-10-27T00:00:00Z',
            'anime': null,
            'manga': {
              'id': 'uuid-m',
              'anilistId': 30013,
              'malId': 13,
              'title': 'Manga',
              'imageUrl': null,
            },
            'tvShow': null,
            'game': null,
          },
        },
      ]),
      <http.BaseRequest>[],
    ).notifications();

    final media = page.items.single.releaseEvent!.media!;
    expect(media.detailId, '30013');
    expect(page.items.single.releaseEvent!.detailType, MediaType.manga);
  });

  test('unreadCount reads count envelope', () async {
    final requests = <http.BaseRequest>[];
    final count = await service({'count': 7}, requests).unreadCount();
    expect(count, 7);
    expect(requests.single.url.path, '/notifications/unread/count');
  });

  test('unreadCount rejects malformed response', () async {
    expect(
      service({'count': 'x'}, <http.BaseRequest>[]).unreadCount(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.failure,
          'failure',
          ApiFailure.invalidResponse,
        ),
      ),
    );
  });

  test('read/unread/delete use distinct methods on same paths', () async {
    final requests = <http.BaseRequest>[];
    final svc = service({}, requests);
    await svc.markRead('n1');
    await svc.markUnread('n1');
    await svc.delete('n1');
    await svc.markAllRead();
    await svc.markAllUnread();
    await svc.deleteAll();

    expect(requests[0].method, 'POST');
    expect(requests[0].url.path, '/notifications/n1/read');
    expect(requests[1].method, 'DELETE');
    expect(requests[1].url.path, '/notifications/n1/read');
    expect(requests[2].method, 'DELETE');
    expect(requests[2].url.path, '/notifications/n1');
    expect(requests[3].method, 'POST');
    expect(requests[3].url.path, '/notifications/read/all');
    expect(requests[4].method, 'DELETE');
    expect(requests[4].url.path, '/notifications/read/all');
    expect(requests[5].method, 'DELETE');
    expect(requests[5].url.path, '/notifications/all');
  });
}
