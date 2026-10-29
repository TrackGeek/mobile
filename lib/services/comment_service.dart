import '../models/api_exception.dart';
import '../models/feed_entry.dart';
import '../models/paginated_page.dart';
import '../models/profile_comment.dart';
import 'api_client.dart';

typedef CommentTarget = ({String type, String id});

const commentTargetField = {
  'Anime': 'animeId',
  'Manga': 'mangaId',
  'TVShow': 'tvShowId',
  'Movie': 'movieId',
  'Game': 'gameId',
  'Book': 'bookId',
  'Profile': 'profileId',
};

class CommentService {
  const CommentService(this._api);

  final ApiClient _api;

  Map<String, String> _params(CommentTarget target) => {
    'type': target.type,
    commentTargetField[target.type]!: target.id,
  };

  Future<PaginatedPage<ProfileComment>> comments(
    CommentTarget target, {
    int page = 1,
    int itemsPerPage = 10,
    String language = 'en-US',
    Future<void>? cancelWhen,
  }) async {
    final res = await _api.requestJson(
      'GET',
      'comment',
      query: {
        ..._params(target),
        'page': '$page',
        'itemsPerPage': '$itemsPerPage',
      },
      language: language,
      cancelWhen: cancelWhen,
    );
    try {
      return PaginatedPage.fromJson(
        res.json?['comments'] as Map<String, dynamic>,
        ProfileComment.fromJson,
      );
    } on TypeError {
      throw const ApiException(ApiFailure.invalidResponse);
    } on FormatException {
      throw const ApiException(ApiFailure.invalidResponse);
    }
  }

  Future<void> addComment(
    CommentTarget target, {
    required String content,
    bool isSpoiler = false,
    String? parentId,
  }) => _api.requestJson(
    'POST',
    'comment',
    body: {
      ..._params(target),
      'content': content,
      'isSpoiler': isSpoiler,
      'parentId': ?parentId,
    },
  );

  Future<void> deleteComment(String commentId) =>
      _api.requestJson('DELETE', 'comment/$commentId');

  Future<FeedReaction?> toggleReaction(
    String commentId, {
    required String emoji,
    FeedReaction? currentReaction,
  }) async {
    if (currentReaction != null) {
      await _api.requestJson('DELETE', 'reaction/${currentReaction.id}');
      if (currentReaction.emoji == emoji) return null;
    }
    final res = await _api.requestJson(
      'POST',
      'reaction',
      body: {'type': 'Comment', 'emoji': emoji, 'commentId': commentId},
    );
    final reaction = res.json?['reaction'];
    if (reaction is Map<String, dynamic>) {
      return FeedReaction.fromJson(reaction);
    }
    return null;
  }
}
