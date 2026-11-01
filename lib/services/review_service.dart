import '../models/api_exception.dart';
import '../models/feed_entry.dart';
import '../models/media_type.dart';
import '../models/paginated_page.dart';
import '../models/review.dart';
import 'api_client.dart';

class ReviewService {
  const ReviewService(this._api);

  final ApiClient _api;

  Future<PaginatedPage<UserReview>> userReviews(
    MediaType type, {
    required String userId,
    String query = '',
    int page = 1,
    int itemsPerPage = 20,
    String? language,
    Future<void>? cancelWhen,
  }) async {
    final config = reviewContent[type]!;
    final res = await _api.requestJson(
      'GET',
      config.endpoint,
      query: {
        'userId': userId,
        if (query.trim().isNotEmpty) 'query': query.trim(),
        'page': '$page',
        'itemsPerPage': '$itemsPerPage',
      },
      language: language,
      cancelWhen: cancelWhen,
    );
    try {
      return PaginatedPage.fromJson(
        res.json?[config.envelope] as Map<String, dynamic>,
        (item) => UserReview.fromJson(type, item),
      );
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    } on FormatException {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  Future<PaginatedPage<UserReview>> mediaReviews(
    MediaType type, {
    required String mediaId,
    String? userId,
    int page = 1,
    int itemsPerPage = 20,
    String? language,
    Future<void>? cancelWhen,
  }) async {
    final config = reviewContent[type]!;
    final res = await _api.requestJson(
      'GET',
      config.endpoint,
      query: {
        config.mediaIdField: mediaId,
        'userId': ?userId,
        'page': '$page',
        'itemsPerPage': '$itemsPerPage',
      },
      language: language,
      cancelWhen: cancelWhen,
    );
    try {
      return PaginatedPage.fromJson(
        res.json?[config.envelope] as Map<String, dynamic>,
        (item) => UserReview.fromJson(type, item),
      );
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    } on FormatException {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  Future<UserReview?> ownReview(
    MediaType type, {
    required String mediaId,
    required String userId,
    Future<void>? cancelWhen,
  }) async {
    final page = await mediaReviews(
      type,
      mediaId: mediaId,
      userId: userId,
      itemsPerPage: 1,
      cancelWhen: cancelWhen,
    );
    return page.items.isEmpty ? null : page.items.first;
  }

  Future<void> createReview(
    MediaType type, {
    required String mediaId,
    required Map<String, Object?> fields,
  }) async {
    final config = reviewContent[type]!;
    await _api.requestJson(
      'POST',
      config.endpoint,
      body: {config.mediaIdField: mediaId, ...fields},
    );
  }

  Future<void> deleteReview(UserReview review) async {
    final config = reviewContent[review.type]!;
    final mediaId = review.media?['id'];
    await _api.requestJson(
      'DELETE',
      '${config.endpoint}/${review.id}',
      body: {config.mediaIdField: '$mediaId'},
    );
  }

  Future<void> updateReview(
    UserReview review, {
    required Map<String, Object?> fields,
  }) async {
    final config = reviewContent[review.type]!;
    await _api.requestJson(
      'PATCH',
      '${config.endpoint}/${review.id}',
      body: {
        config.mediaIdField: '${review.media?['id']}',
        'overall': fields['overall'],
        ...fields,
      },
    );
  }

  Future<FeedReaction?> toggleReaction(
    UserReview review, {
    required String emoji,
    FeedReaction? currentReaction,
  }) async {
    if (currentReaction != null) {
      await _api.requestJson('DELETE', 'reaction/${currentReaction.id}');
      if (currentReaction.emoji == emoji) return null;
    }
    final config = reviewContent[review.type]!;
    final res = await _api.requestJson(
      'POST',
      'reaction',
      body: {
        'type': config.reactionType,
        'emoji': emoji,
        config.reactionIdField: review.id,
      },
    );
    final reaction = res.json?['reaction'];
    if (reaction is Map<String, dynamic>) {
      return FeedReaction.fromJson(reaction);
    }
    return null;
  }
}
