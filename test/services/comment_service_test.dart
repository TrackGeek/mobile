import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trackgeek/app/api_config.dart';
import 'package:trackgeek/services/api_client.dart';
import 'package:trackgeek/services/comment_service.dart';

void main() {
  CommentService service(
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
    return CommentService(api);
  }

  final pageResponse = {
    'comments': {
      'items': <dynamic>[],
      'total': 0,
      'pages': 0,
      'inPage': 1,
      'itemsInPage': 0,
      'itemsPerPage': 10,
    },
  };

  test('book target maps to type Book and bookId', () async {
    final requests = <http.BaseRequest>[];
    await service(pageResponse, requests).comments((type: 'Book', id: 'b1'));
    final params = requests.single.url.queryParameters;
    expect(params['type'], 'Book');
    expect(params['bookId'], 'b1');
    expect(params.containsKey('profileId'), isFalse);
  });

  test('profile target maps to type Profile and profileId', () async {
    final requests = <http.BaseRequest>[];
    await service(pageResponse, requests).comments((type: 'Profile', id: 'p1'));
    final params = requests.single.url.queryParameters;
    expect(params['type'], 'Profile');
    expect(params['profileId'], 'p1');
  });

  test('addComment posts target fields and content', () async {
    final requests = <http.BaseRequest>[];
    await service({}, requests).addComment(
      (type: 'Book', id: 'b1'),
      content: 'hello',
      isSpoiler: true,
      parentId: 'c9',
    );
    final request = requests.single;
    expect(request.method, 'POST');
    expect(request.url.path, endsWith('/comment'));
    expect(jsonDecode((request as http.Request).body), {
      'type': 'Book',
      'bookId': 'b1',
      'content': 'hello',
      'isSpoiler': true,
      'parentId': 'c9',
    });
  });

  test('deleteComment calls DELETE comment/id', () async {
    final requests = <http.BaseRequest>[];
    await service({}, requests).deleteComment('c1');
    expect(requests.single.method, 'DELETE');
    expect(requests.single.url.path, endsWith('/comment/c1'));
  });
}
