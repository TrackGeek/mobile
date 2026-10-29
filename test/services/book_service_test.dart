import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trackgeek/app/api_config.dart';
import 'package:trackgeek/models/api_exception.dart';
import 'package:trackgeek/services/api_client.dart';
import 'package:trackgeek/services/book_service.dart';

void main() {
  BookService service(
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
    return BookService(api);
  }

  final detailResponse = {
    'book': {
      'id': 'book-uuid',
      'hardcoverId': 1974594,
      'slug': 'the-book',
      'title': 'The Book',
      'imageUrl': {'url': 'https://img/cover.jpg'},
      'numberOfPages': 290,
      'releaseYear': 2020,
      'tgReviewScore': 4.2,
      'contributions': [
        {
          'contribution': 'Author',
          'author': {'id': 7, 'name': 'Jane Doe'},
        },
      ],
      'taggings': [
        {'tag': 'Fantasy'},
      ],
      'editions': [
        {'id': 11, 'title': 'Hardcover', 'numberOfPages': 290},
      ],
      'defaultPhysicalEdition': {
        'id': 11,
        'publisher': 'Pub',
        'language': 'English',
      },
      'bookSeries': [
        {
          'id': 5,
          'position': 2.0,
          'series': {'id': 90, 'name': 'Saga'},
        },
      ],
      'bookCategory': {'name': 'Fiction'},
      'editionsCount': 3,
      'coverEditionId': 11,
      'customCoverEditionId': 22,
      'progressStats': {
        'planToRead': {'count': 8, 'percentage': 40.0},
        'reading': {'count': 6, 'percentage': 30.0},
        'completed': {'count': 4, 'percentage': 20.0},
        'dropped': {'count': 2, 'percentage': 10.0},
      },
    },
  };

  test('detail calls book/detail and parses the book envelope', () async {
    final requests = <http.BaseRequest>[];
    final book = await service(detailResponse, requests).detail('1974594');

    expect(requests.single.url.path, endsWith('/book/detail/1974594'));
    expect(book.id, 'book-uuid');
    expect(book.hardcoverId, 1974594);
    expect(book.imageUrl, 'https://img/cover.jpg');
    expect(book.authors, ['Jane Doe']);
    expect(book.taggings, ['Fantasy']);
    expect(book.bookSeries.single.series.name, 'Saga');
    expect(book.bookSeries.single.positionLabel, '2');
    expect(book.primaryEdition?.publisher, 'Pub');
    expect(book.category, 'Fiction');
    expect(book.customCoverEditionId, 22);
    expect(book.progressStats?.planToRead.count, 8);
  });

  test('detail rejects malformed response', () async {
    await expectLater(
      service({}, []).detail('1'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.failure,
          'failure',
          ApiFailure.invalidResponse,
        ),
      ),
    );
  });

  test('franchise calls book/franchise and parses books', () async {
    final requests = <http.BaseRequest>[];
    final franchise = await service({
      'franchise': {
        'id': 90,
        'name': 'Saga',
        'slug': '90-saga',
        'imageUrl': 'https://img/banner.jpg',
        'books': [
          {
            'hardcoverId': 1974594,
            'position': 1.0,
            'title': 'The Book',
            'imageUrl': {'url': 'https://img/cover.jpg'},
            'releaseYear': 2020,
          },
        ],
      },
    }, requests).franchise('90-saga');

    expect(requests.single.url.path, endsWith('/book/franchise/90-saga'));
    expect(franchise.name, 'Saga');
    expect(franchise.books.single.hardcoverId, 1974594);
    expect(franchise.books.single.imageUrl, 'https://img/cover.jpg');
  });

  test('progress sends userId and bookId query params', () async {
    final requests = <http.BaseRequest>[];
    final progress = await service({
      'bookProgresses': {
        'items': [
          {'id': 'p1', 'status': 'Reading', 'chaptersRead': 40},
        ],
      },
    }, requests).progress('u1', 'b1');

    final uri = requests.single.url;
    expect(uri.path, endsWith('/book/progress'));
    expect(uri.queryParameters['userId'], 'u1');
    expect(uri.queryParameters['bookId'], 'b1');
    expect(progress?.id, 'p1');
    expect(progress?.chaptersRead, 40);
  });

  test('progress returns null for empty list', () async {
    final progress = await service({
      'bookProgresses': {'items': <dynamic>[]},
    }, []).progress('u1', 'b1');
    expect(progress, isNull);
  });

  test('saveProgress posts status and fields', () async {
    final requests = <http.BaseRequest>[];
    await service({}, requests).saveProgress(
      'b1',
      status: 'Completed',
      pagesRead: 290,
      totalPages: 290,
      readCount: 2,
      startedAt: '2024-01-01T00:00:00.000',
      completedAt: '2024-02-01T00:00:00.000',
    );

    final request = requests.single;
    expect(request.method, 'POST');
    expect(request.url.path, endsWith('/book/progress'));
    expect(jsonDecode((request as http.Request).body), {
      'bookId': 'b1',
      'status': 'Completed',
      'chaptersRead': 290,
      'totalPages': 290,
      'readCount': 2,
      'startedAt': '2024-01-01T00:00:00.000',
      'completedAt': '2024-02-01T00:00:00.000',
    });
  });

  test('deleteProgress calls DELETE book/progress/id', () async {
    final requests = <http.BaseRequest>[];
    await service({}, requests).deleteProgress('p1');
    expect(requests.single.method, 'DELETE');
    expect(requests.single.url.path, endsWith('/book/progress/p1'));
  });

  test('refresh posts hardcoverId', () async {
    final requests = <http.BaseRequest>[];
    await service({}, requests).refresh(1974594);
    final request = requests.single;
    expect(request.method, 'POST');
    expect(request.url.path, endsWith('/book/refresh'));
    expect(jsonDecode((request as http.Request).body), {
      'hardcoverId': 1974594,
    });
  });

  test('setCover PUTs editionId; resetCover DELETEs', () async {
    final requests = <http.BaseRequest>[];
    final svc = service({}, requests);
    await svc.setCover(1974594, 11);
    expect(requests.last.method, 'PUT');
    expect(requests.last.url.path, endsWith('/book/cover/1974594'));
    expect(jsonDecode((requests.last as http.Request).body), {'editionId': 11});
    await svc.resetCover(1974594);
    expect(requests.last.method, 'DELETE');
    expect(requests.last.url.path, endsWith('/book/cover/1974594'));
  });
}
