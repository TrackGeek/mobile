import '../models/api_exception.dart';
import '../models/game_detail.dart';
import '../models/game_screenshot.dart';
import '../models/paginated_page.dart';
import 'api_client.dart';

class GameService {
  const GameService(this._api);

  final ApiClient _api;

  Future<GameDetail> detail(
    int igdbId, {
    String language = 'en-US',
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'game/detail/$igdbId',
      language: language,
      cancelWhen: cancelWhen,
    );
    final game = res.json?['game'];
    if (game is! Map<String, dynamic>) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    try {
      return GameDetail.fromJson(game);
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  Future<GameFranchise> franchise(
    String slug, {
    String language = 'en-US',
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'game/franchise/$slug',
      language: language,
      cancelWhen: cancelWhen,
    );
    final franchise = res.json?['franchise'];
    if (franchise is! Map<String, dynamic>) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    try {
      return GameFranchise.fromJson(franchise);
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  Future<GameProgress?> progress(
    String userId,
    String gameId, {
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'game/progress',
      query: {'userId': userId, 'gameId': gameId},
      cancelWhen: cancelWhen,
    );
    final items = res.json?['gameProgresses'];
    final list = items is Map<String, dynamic> ? items['items'] : items;
    if (list is! List) return null;
    for (final item in list) {
      if (item is Map<String, dynamic>) return GameProgress.fromJson(item);
    }
    return null;
  }

  Future<void> saveProgress(
    String gameId, {
    required String status,
    int? playCount,
    String? completion,
    List<String>? platforms,
    int? hoursPlayed,
    String? notes,
    String? startedAt,
    String? completedAt,
  }) => _api.requestJson(
    'POST',
    'game/progress',
    body: {
      'gameId': gameId,
      'status': status,
      'playCount': ?playCount,
      'completion': ?completion,
      'platforms': ?platforms,
      'hoursPlayed': ?hoursPlayed,
      'notes': ?notes,
      'startedAt': ?startedAt,
      'completedAt': ?completedAt,
    },
  );

  Future<void> deleteProgress(String gameProgressId) =>
      _api.requestJson('DELETE', 'game/progress/$gameProgressId');

  Future<void> resetTracking(String gameId) =>
      _api.requestJson('DELETE', 'game/tracking/$gameId');

  Future<void> refresh(int igdbId) =>
      _api.requestJson('POST', 'game/refresh', body: {'igdbId': igdbId});

  Future<GameScreenshot> createScreenshot({
    required String gameId,
    required String url,
    String? type,
    String? description,
    bool? isSpoiler,
  }) async {
    final res = await _api.requestJson(
      'POST',
      'game/screenshot',
      body: {
        'gameId': gameId,
        'url': url,
        'type': ?type,
        'description': ?description,
        'isSpoiler': ?isSpoiler,
      },
    );
    final screenshot = res.json?['screenshot'];
    if (screenshot is! Map<String, dynamic>) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    return GameScreenshot.fromJson(screenshot);
  }

  Future<GameScreenshot> updateScreenshot(
    String screenshotId, {
    String? description,
    bool? isSpoiler,
  }) async {
    final res = await _api.requestJson(
      'PATCH',
      'game/screenshot/$screenshotId',
      body: {'description': ?description, 'isSpoiler': ?isSpoiler},
    );
    final screenshot = res.json?['screenshot'];
    if (screenshot is! Map<String, dynamic>) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    return GameScreenshot.fromJson(screenshot);
  }

  Future<void> deleteScreenshot(String screenshotId) =>
      _api.requestJson('DELETE', 'game/screenshot/$screenshotId');

  Future<PaginatedPage<GameScreenshot>> screenshots({
    String? userId,
    String? gameId,
    int page = 1,
    int itemsPerPage = 18,
    String language = 'en-US',
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'game/screenshot/',
      query: {
        'userId': ?userId,
        'gameId': ?gameId,
        'page': '$page',
        'itemsPerPage': '$itemsPerPage',
      },
      language: language,
      cancelWhen: cancelWhen,
    );
    try {
      return PaginatedPage.fromJson(
        res.json?['screenshots'] as Map<String, dynamic>,
        GameScreenshot.fromJson,
      );
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    } on FormatException {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  Future<String> uploadImage(
    List<int> bytes, {
    required String filename,
    String? mimeType,
    String language = 'en-US',
  }) async {
    final res = await _api.sendMultipart(
      'POST',
      'upload/image',
      bytes: bytes,
      filename: filename,
      mimeType: mimeType,
      language: language,
    );
    final url = res.json?['imageUrl'];
    if (url is! String) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    return url;
  }
}
