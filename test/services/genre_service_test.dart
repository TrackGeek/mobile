import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trackgeek/models/media_type.dart';
import 'package:trackgeek/services/genre_service.dart';

void main() {
  GenreService service(Future<http.Response> Function(http.Request) respond) =>
      GenreService(client: MockClient(respond));

  test('maps remote genre names for anime and manga', () async {
    final genres = await service(
      (_) async => http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'data': [
              {'name': 'Action', 'mal_id': 1},
              {'name': 'Isekai', 'mal_id': 2},
              {'name': 3},
            ],
          }),
        ),
        200,
      ),
    ).genres(MediaType.anime);
    expect(genres, ['Action', 'Isekai']);
  });

  test('requests the matching tenrai path', () async {
    Uri? requested;
    await service((request) async {
      requested = request.url;
      return http.Response('{"data": []}', 200);
    }).genres(MediaType.manga);
    expect(requested.toString(), 'https://api.tenrai.org/v1/genres/manga');
  });

  test('returns null on failure or malformed payloads', () async {
    expect(
      await service((_) async => http.Response('oops', 500))
          .genres(MediaType.anime),
      isNull,
    );
    expect(
      await service((_) async => http.Response('{}', 200))
          .genres(MediaType.anime),
      isNull,
    );
    expect(
      await service((_) async => throw http.ClientException('offline'))
          .genres(MediaType.anime),
      isNull,
    );
  });

  test('non-remote types skip the network entirely', () async {
    var called = false;
    final result = await service((_) async {
      called = true;
      return http.Response('{}', 200);
    }).genres(MediaType.movie);
    expect(result, isNull);
    expect(called, isFalse);
  });
}
