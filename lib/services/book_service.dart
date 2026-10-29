import '../models/api_exception.dart';
import '../models/book_detail.dart';
import 'api_client.dart';

class BookService {
  const BookService(this._api);

  final ApiClient _api;

  Future<BookDetail> detail(
    String hardcoverId, {
    String language = 'en-US',
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'book/detail/$hardcoverId',
      language: language,
      cancelWhen: cancelWhen,
    );
    final book = res.json?['book'];
    if (book is! Map<String, dynamic>) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    try {
      return BookDetail.fromJson(book);
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  Future<BookFranchise> franchise(
    String slug, {
    String language = 'en-US',
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'book/franchise/$slug',
      language: language,
      cancelWhen: cancelWhen,
    );
    final franchise = res.json?['franchise'];
    if (franchise is! Map<String, dynamic>) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    try {
      return BookFranchise.fromJson(franchise);
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  Future<BookProgress?> progress(
    String userId,
    String bookId, {
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'book/progress',
      query: {'userId': userId, 'bookId': bookId},
      cancelWhen: cancelWhen,
    );
    final items = res.json?['bookProgresses'];
    final list = items is Map<String, dynamic> ? items['items'] : items;
    if (list is! List) return null;
    for (final item in list) {
      if (item is Map<String, dynamic>) return BookProgress.fromJson(item);
    }
    return null;
  }

  Future<void> saveProgress(
    String bookId, {
    required String status,
    int? pagesRead,
    int? totalPages,
    int? readCount,
    String? startedAt,
    String? completedAt,
  }) => _api.requestJson(
    'POST',
    'book/progress',
    body: {
      'bookId': bookId,
      'status': status,
      'chaptersRead': ?pagesRead,
      'totalPages': ?totalPages,
      'readCount': ?readCount,
      'startedAt': ?startedAt,
      'completedAt': ?completedAt,
    },
  );

  Future<void> deleteProgress(String bookProgressId) =>
      _api.requestJson('DELETE', 'book/progress/$bookProgressId');

  Future<void> refresh(int hardcoverId) => _api.requestJson(
    'POST',
    'book/refresh',
    body: {'hardcoverId': hardcoverId},
  );

  Future<void> setCover(int hardcoverId, int editionId) => _api.requestJson(
    'PUT',
    'book/cover/$hardcoverId',
    body: {'editionId': editionId},
  );

  Future<void> resetCover(int hardcoverId) =>
      _api.requestJson('DELETE', 'book/cover/$hardcoverId');
}
