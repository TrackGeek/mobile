import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trackgeek/app/api_config.dart';
import 'package:trackgeek/models/media_type.dart';
import 'package:trackgeek/models/progress_item.dart';
import 'package:trackgeek/services/api_client.dart';
import 'package:trackgeek/services/progress_service.dart';

ProgressItem item(
  MediaType type, {
  int current = 2,
  int? total = 12,
  String? status,
}) => ProgressItem.fromJson(type, {
  type == MediaType.tv ? 'tvShow' : type.name: {
    'id': 'internal-id',
    'malId': 20,
    'anilistId': 99,
    'tmdbId': 40,
    'hardcoverId': 50,
    'title': 'Example',
    'year': 2026,
    'numberOfChapters': total,
    'numberOfPages': 300,
  },
  'status':
      status ??
      (type == MediaType.book || type == MediaType.manga
          ? 'Reading'
          : 'Watching'),
  'chaptersRead': current,
  'totalPages': total,
  'episodeProgress': {
    'current': current,
    'total': total,
    'next': {'episode': 4, if (type == MediaType.tv) 'season': 2},
  },
});

void main() {
  test(
    'active progress requests each status separately and merges by updatedAt',
    () async {
      final statuses = <String>[];
      final service = ProgressService(
        ApiClient(
          config: ApiConfig(baseUrl: 'https://api.example.test'),
          client: MockClient((request) async {
            statuses.add(request.url.queryParameters['status']!);
            final recent = statuses.last == 'Rewatching';
            return http.Response(
              jsonEncode({
                'animeProgresses': {
                  'items': [
                    {
                      'anime': {
                        'id': 'id-$statuses',
                        'malId': 20,
                        'title': 'Example',
                      },
                      'status': statuses.last,
                      'updatedAt': recent ? '2026-10-20' : '2026-10-25',
                      'episodeProgress': {
                        'current': 2,
                        'total': 12,
                        'next': {'episode': 4},
                      },
                    },
                  ],
                  'inPage': 1,
                  'itemsInPage': 1,
                  'pages': 1,
                  'total': 1,
                  'itemsPerPage': 6,
                },
                'statusCounts': {},
              }),
              200,
            );
          }),
        ),
      );
      final items = await service.activeProgress(
        MediaType.anime,
        userId: 'user-1',
        statuses: const ['Watching', 'Rewatching'],
      );
      expect(statuses, ['Watching', 'Rewatching']);
      expect(items.length, 2);
      expect(items.first.status, 'Watching');
      expect(items.last.status, 'Rewatching');
    },
  );

  test(
    'anime navigates with MAL, mutates internal ID and API next episode',
    () async {
      final progress = item(MediaType.anime);
      expect(progress.detailId, '20');
      expect(progress.year, 2026);
      var changes = 0;
      final service = ProgressService(
        ApiClient(
          config: ApiConfig(baseUrl: 'https://api.example.test'),
          client: MockClient((request) async {
            expect(request.method, 'POST');
            expect(request.url.path, '/anime/episode/watch');
            expect(request.headers['Authorization'], 'Bearer test-token');
            expect(jsonDecode(request.body), {
              'animeId': 'internal-id',
              'episodes': [
                {'episode': 4, 'status': 'Completed'},
              ],
            });
            return http.Response('', 200);
          }),
        )..bearerToken = 'test-token',
      )..addListener(() => changes++);
      await service.increment(progress);
      expect(changes, 1);
    },
  );

  test('TV sends season, books and manga send chaptersRead', () async {
    for (final type in [MediaType.tv, MediaType.book, MediaType.manga]) {
      final service = ProgressService(
        ApiClient(
          config: ApiConfig(baseUrl: 'https://api.example.test'),
          client: MockClient((request) async {
            final body = jsonDecode(request.body);
            if (type == MediaType.tv) {
              expect(request.url.path, '/tv/episode/watch');
              expect(body, {
                'tvShowId': 'internal-id',
                'episodes': [
                  {'episode': 4, 'season': 2, 'status': 'Completed'},
                ],
              });
            } else {
              expect(request.url.path, '/${type.name}/progress');
              expect(body, {
                '${type.name}Id': 'internal-id',
                'status': 'Reading',
                'chaptersRead': 3,
              });
            }
            return http.Response('', 200);
          }),
        ),
      );
      await service.increment(item(type));
    }
  });

  test('reading totals use edition override and unknown totals remain incrementable', () {
    expect(item(MediaType.book, total: 100).total, 100);
    expect(item(MediaType.manga, total: null).total, isNull);
    expect(item(MediaType.manga, total: null).canIncrement, isTrue);
    expect(item(MediaType.manga, current: 12).canIncrement, isFalse);
    expect(item(MediaType.manga, status: 'Completed').canIncrement, isFalse);
    expect(item(MediaType.anime, status: 'Paused').canIncrement, isFalse);
  });

  test('duplicate in-flight requests blocked; failures notify no success and allow retry', () async {
    final response = Completer<http.Response>();
    var calls = 0;
    var changes = 0;
    final service = ProgressService(
      ApiClient(
        config: ApiConfig(baseUrl: 'https://api.example.test'),
        client: MockClient((_) {
          calls++;
          return response.future;
        }),
      ),
    )..addListener(() => changes++);
    final pending = service.increment(item(MediaType.manga));
    await service.increment(item(MediaType.manga));
    response.complete(http.Response('{}', 500));
    await expectLater(pending, throwsException);
    expect(calls, 1);
    expect(changes, 0);
    await expectLater(
      service.increment(item(MediaType.manga)),
      throwsException,
    );
    expect(calls, 2);
    await service.increment(item(MediaType.manga, current: 12));
    expect(calls, 2);
  });
}
