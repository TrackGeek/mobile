import '../models/api_exception.dart';
import '../models/manga_detail.dart';
import 'api_client.dart';

class MangaService {
  const MangaService(this._api);

  final ApiClient _api;

  Future<MangaDetail> detail(
    int anilistId, {
    String language = 'en-US',
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'manga/detail/$anilistId',
      language: language,
      cancelWhen: cancelWhen,
    );
    final manga = res.json?['manga'];
    if (manga is! Map<String, dynamic>) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    try {
      return MangaDetail.fromJson(manga);
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  Future<MangaProgress?> progress(
    String userId,
    String mangaId, {
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'manga/progress',
      query: {'userId': userId, 'mangaId': mangaId},
      cancelWhen: cancelWhen,
    );
    final items = res.json?['mangaProgresses'];
    final list = items is Map<String, dynamic> ? items['items'] : items;
    if (list is! List) return null;
    for (final item in list) {
      if (item is Map<String, dynamic>) return MangaProgress.fromJson(item);
    }
    return null;
  }

  Future<void> saveProgress(
    String mangaId, {
    required String status,
    int? chaptersRead,
    int? readCount,
    String? startedAt,
    String? completedAt,
  }) => _api.requestJson(
    'POST',
    'manga/progress',
    body: {
      'mangaId': mangaId,
      'status': status,
      'chaptersRead': ?chaptersRead,
      'readCount': ?readCount,
      'startedAt': ?startedAt,
      'completedAt': ?completedAt,
    },
  );

  Future<void> deleteProgress(String mangaProgressId) =>
      _api.requestJson('DELETE', 'manga/progress/$mangaProgressId');

  Future<void> refresh(int anilistId) =>
      _api.requestJson('POST', 'manga/refresh', body: {'anilistId': anilistId});
}
