import '../models/api_exception.dart';
import '../models/feed_entry.dart';
import '../models/feed_normalize.dart';
import '../models/media_type.dart';
import 'api_client.dart';

class ActivityPage {
  const ActivityPage({
    required this.inPage,
    required this.pages,
    required this.entries,
  });

  final int inPage;
  final int? pages;
  final List<FeedEntry> entries;

  bool get hasNextPage => pages != null && inPage < pages!;
}

class ActivityService {
  const ActivityService(this._api);

  final ApiClient _api;

  static const itemsPerPage = 50;

  static const _paths = {
    FeedKind.global: 'activities/global',
    FeedKind.following: 'activities/following',
    FeedKind.trending: 'activities/trending',
  };

  static const _apiType = {
    MediaType.movie: 'Movie',
    MediaType.tv: 'TVShow',
    MediaType.game: 'Game',
    MediaType.anime: 'Anime',
    MediaType.manga: 'Manga',
    MediaType.book: 'Book',
  };

  Future<ActivityPage> feed(
    FeedKind kind, {
    int page = 1,
    String? language,
    Future<void>? cancelWhen,
  }) => _activities(
    _paths[kind]!,
    page: page,
    language: language,
    cancelWhen: cancelWhen,
  );

  Future<ActivityPage> userActivities(
    String userId, {
    int page = 1,
    String? language,
    Future<void>? cancelWhen,
  }) => _activities(
    'activities/user/$userId',
    page: page,
    language: language,
    cancelWhen: cancelWhen,
  );

  Future<ActivityPage> _activities(
    String path, {
    required int page,
    String? language,
    Future<void>? cancelWhen,
  }) async {
    final response = await _api.requestJson(
      'GET',
      path,
      query: {'page': '$page', 'itemsPerPage': '$itemsPerPage'},
      language: language,
      cancelWhen: cancelWhen,
    );
    final envelope = response.json?['activities'];
    if (envelope is! Map<String, dynamic>) {
      throw const ApiException(ApiFailure.invalidResponse);
    }
    try {
      final items = envelope['items'] as List;
      return ActivityPage(
        inPage: envelope['inPage'] as int,
        pages: envelope['pages'] as int?,
        entries: [
          for (final group in items)
            if (group is Map<String, dynamic>) ?normalizeActivityGroup(group),
        ],
      );
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  Future<FeedReaction?> toggleReaction({
    required String activityId,
    required String emoji,
    FeedReaction? currentReaction,
  }) async {
    if (currentReaction != null) {
      await _api.requestJson('DELETE', 'reaction/${currentReaction.id}');
      if (currentReaction.emoji == emoji) return null;
    }
    final response = await _api.requestJson(
      'POST',
      'reaction',
      body: {'type': 'Activity', 'emoji': emoji, 'activityId': activityId},
    );
    final reaction = response.json?['reaction'];
    if (reaction is Map<String, dynamic>) {
      return FeedReaction.fromJson(reaction);
    }
    return null;
  }

  Future<void> createPost({
    required String content,
    bool isSpoiler = false,
    MediaType? mediaType,
    int? mediaExternalId,
  }) async {
    await _api.requestJson(
      'POST',
      'post',
      body: {
        'content': content,
        'isSpoiler': isSpoiler,
        if (mediaType != null && mediaExternalId != null) ...{
          'mediaType': ?_apiType[mediaType],
          'mediaExternalId': mediaExternalId,
        },
      },
    );
  }

  Future<void> updatePost(
    String postId, {
    String? content,
    bool? isSpoiler,
  }) async {
    await _api.requestJson(
      'PATCH',
      'post/$postId',
      body: {'content': ?content, 'isSpoiler': ?isSpoiler},
    );
  }

  Future<void> deletePost(String postId) =>
      _api.requestJson('DELETE', 'post/$postId');
}
