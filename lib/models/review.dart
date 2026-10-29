import 'feed_entry.dart';
import 'follow.dart';
import 'media_type.dart';

class UserReview {
  const UserReview({
    required this.id,
    required this.type,
    required this.overall,
    required this.fields,
    this.summary,
    this.notes,
    this.story,
    this.recommended,
    this.createdAt,
    this.media,
    this.user,
    this.reactions = const [],
  });

  final String id;
  final MediaType type;
  final double overall;
  final Map<String, double> fields;
  final String? summary;
  final String? notes;
  final String? story;
  final bool? recommended;
  final DateTime? createdAt;
  final Map<String, dynamic>? media;
  final FollowUser? user;
  final List<FeedReaction> reactions;

  factory UserReview.fromJson(MediaType type, Map<String, dynamic> json) {
    double? numValue(String key) {
      final value = json[key];
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    final mediaKey = switch (type) {
      MediaType.tv => 'tvShow',
      _ => type.name,
    };
    return UserReview(
      id: '${json['id']}',
      type: type,
      overall: numValue('overall') ?? 0,
      fields: {
        for (final key in reviewContent[type]!.criteria)
          if (numValue(key) != null) key: numValue(key)!,
      },
      summary: json['summary'] as String?,
      notes: json['notes'] as String?,
      story: json['story'] is String ? json['story'] as String : null,
      recommended: json['recommended'] as bool?,
      createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}'),
      media: json[mediaKey] is Map<String, dynamic>
          ? json[mediaKey] as Map<String, dynamic>
          : null,
      user: json['user'] is Map<String, dynamic>
          ? FollowUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      reactions: [
        for (final r in json['reactions'] as List? ?? const [])
          if (r is Map<String, dynamic>) FeedReaction.fromJson(r),
      ],
    );
  }

  String get mediaTitle => '${media?['title'] ?? media?['name'] ?? ''}';

  String get mediaImage =>
      '${media?['coverUrl'] ?? media?['posterUrl'] ?? media?['imageUrl'] ?? ''}';

  String? get mediaEntityId {
    final key = switch (type) {
      MediaType.anime => 'malId',
      MediaType.manga => 'anilistId',
      MediaType.tv || MediaType.movie => 'tmdbId',
      MediaType.game => 'igdbId',
      MediaType.book => 'hardcoverId',
    };
    final value = media?[key];
    return value == null ? null : '$value';
  }
}

class ReviewContentConfig {
  const ReviewContentConfig({
    required this.endpoint,
    required this.envelope,
    required this.mediaIdField,
    required this.reactionType,
    required this.reactionIdField,
    required this.hasStory,
    required this.criteria,
    required this.criteriaLabels,
  });

  final String endpoint;
  final String envelope;
  final String mediaIdField;
  final String reactionType;
  final String reactionIdField;
  final bool hasStory;
  final List<String> criteria;
  final Map<String, String> criteriaLabels;
}

const reviewContent = <MediaType, ReviewContentConfig>{
  MediaType.tv: ReviewContentConfig(
    endpoint: 'tv/review',
    envelope: 'tvShowReviews',
    mediaIdField: 'tvShowId',
    reactionType: 'TvShowReview',
    reactionIdField: 'tvShowReviewId',
    hasStory: true,
    criteria: ['direction', 'production', 'acting'],
    criteriaLabels: {
      'direction': 'direction',
      'production': 'production',
      'acting': 'acting',
    },
  ),
  MediaType.movie: ReviewContentConfig(
    endpoint: 'movie/review',
    envelope: 'movieReviews',
    mediaIdField: 'movieId',
    reactionType: 'MovieReview',
    reactionIdField: 'movieReviewId',
    hasStory: true,
    criteria: ['direction', 'production', 'acting'],
    criteriaLabels: {
      'direction': 'direction',
      'production': 'production',
      'acting': 'acting',
    },
  ),
  MediaType.game: ReviewContentConfig(
    endpoint: 'game/review',
    envelope: 'gameReviews',
    mediaIdField: 'gameId',
    reactionType: 'GameReview',
    reactionIdField: 'gameReviewId',
    hasStory: false,
    criteria: ['graphics', 'sound', 'story', 'gameplay'],
    criteriaLabels: {
      'graphics': 'graphics',
      'sound': 'soundtrack',
      'story': 'story',
      'gameplay': 'gameplay',
    },
  ),
  MediaType.anime: ReviewContentConfig(
    endpoint: 'anime/review',
    envelope: 'animeReviews',
    mediaIdField: 'animeId',
    reactionType: 'AnimeReview',
    reactionIdField: 'animeReviewId',
    hasStory: false,
    criteria: ['story', 'characters', 'animation', 'sound', 'enjoyment'],
    criteriaLabels: {
      'story': 'story',
      'characters': 'characters',
      'animation': 'animation',
      'sound': 'soundtrack',
      'enjoyment': 'enjoyment',
    },
  ),
  MediaType.book: ReviewContentConfig(
    endpoint: 'book/review',
    envelope: 'bookReviews',
    mediaIdField: 'bookId',
    reactionType: 'BookReview',
    reactionIdField: 'bookReviewId',
    hasStory: false,
    criteria: ['characters', 'language', 'theme'],
    criteriaLabels: {
      'characters': 'characters',
      'language': 'language',
      'theme': 'theme',
    },
  ),
  MediaType.manga: ReviewContentConfig(
    endpoint: 'manga/review',
    envelope: 'mangaReviews',
    mediaIdField: 'mangaId',
    reactionType: 'MangaReview',
    reactionIdField: 'mangaReviewId',
    hasStory: true,
    criteria: ['art', 'worldbuilding'],
    criteriaLabels: {'art': 'art', 'worldbuilding': 'worldbuilding'},
  ),
};
