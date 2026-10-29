import 'media_type.dart';

enum FeedKind { following, global, trending, user }

enum FeedEntryKind { item, review, post, screenshot }

class FeedProfile {
  const FeedProfile({
    required this.name,
    required this.avatarUrl,
    this.username,
  });

  final String name;
  final String avatarUrl;
  final String? username;
}

class FeedReaction {
  const FeedReaction({
    required this.id,
    required this.emoji,
    required this.userId,
    required this.username,
  });

  final String id;
  final String emoji;
  final String userId;
  final String username;

  factory FeedReaction.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return FeedReaction(
      id: json['id'] as String,
      emoji: json['emoji'] as String,
      userId: user is Map<String, dynamic> ? '${user['id']}' : '',
      username: user is Map<String, dynamic> ? '${user['username'] ?? ''}' : '',
    );
  }
}

sealed class FeedTitleLink {
  const FeedTitleLink();
}

final class FeedMediaTitleLink extends FeedTitleLink {
  const FeedMediaTitleLink({
    required this.slug,
    this.type,
    this.person = false,
  });

  final String slug;
  final MediaType? type;
  final bool person;
}

final class FeedUserTitleLink extends FeedTitleLink {
  const FeedUserTitleLink({required this.username, required this.tab});

  final String username;
  final String tab;
}

class FeedMediaLink {
  const FeedMediaLink({required this.slug, this.type, this.person = false});

  final String slug;
  final MediaType? type;
  final bool person;
}

class FeedScreenshot {
  const FeedScreenshot({
    required this.id,
    required this.url,
    required this.type,
    this.description,
    this.isSpoiler = false,
  });

  final String id;
  final String url;
  final String type;
  final String? description;
  final bool isSpoiler;
}

class FeedEntry {
  FeedEntry({
    required this.kind,
    required this.profile,
    required this.titleKey,
    required this.time,
    required this.activityType,
    this.coverUrl = '',
    this.titleValues,
    this.titleLink,
    this.mediaTitle,
    this.content,
    this.likes = 0,
    this.media,
    this.activityId,
    List<FeedReaction>? reactions,
    this.postId,
    this.authorId,
    this.isSpoiler = false,
    this.screenshots = const [],
  }) : reactions = reactions ?? [];

  final FeedEntryKind kind;
  final FeedProfile profile;
  final String coverUrl;
  final String activityType;
  final String titleKey;
  final Map<String, Object>? titleValues;
  final FeedTitleLink? titleLink;
  final String? mediaTitle;
  final String? content;
  final DateTime time;
  final int likes;
  final FeedMediaLink? media;
  final String? activityId;
  final List<FeedReaction> reactions;

  final String? postId;
  final String? authorId;
  final bool isSpoiler;
  final List<FeedScreenshot> screenshots;
}
