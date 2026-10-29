import 'media_type.dart';

class AppNotification {
  AppNotification.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      type = json['type'] as String,
      readAt = json['readAt'] as String?,
      createdAt = json['createdAt'] as String,
      metadata = json['metadata'] is Map<String, dynamic>
          ? json['metadata'] as Map<String, dynamic>
          : null,
      actor = json['actor'] is Map<String, dynamic>
          ? NotificationActor.fromJson(json['actor'] as Map<String, dynamic>)
          : null,
      comment = json['comment'] is Map<String, dynamic>
          ? NotificationComment.fromJson(
              json['comment'] as Map<String, dynamic>,
            )
          : null,
      reaction = json['reaction'] is Map<String, dynamic>
          ? NotificationReaction.fromJson(
              json['reaction'] as Map<String, dynamic>,
            )
          : null,
      releaseEvent = json['releaseEvent'] is Map<String, dynamic>
          ? ReleaseEvent.fromJson(json['releaseEvent'] as Map<String, dynamic>)
          : null;

  final String id;
  final String type;
  final String? readAt;
  final String createdAt;
  final Map<String, dynamic>? metadata;
  final NotificationActor? actor;
  final NotificationComment? comment;
  final NotificationReaction? reaction;
  final ReleaseEvent? releaseEvent;

  bool get isRead => readAt != null;

  bool get isSystem =>
      type == 'System' || type == 'LevelUp' || type == 'MissionCompleted';
}

class NotificationActor {
  NotificationActor.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      name = json['name'] as String? ?? '',
      username = json['username'] as String? ?? '',
      avatarUrl = json['profile'] is Map<String, dynamic>
          ? (json['profile'] as Map<String, dynamic>)['avatarUrl'] as String?
          : null;

  final String id;
  final String name;
  final String username;
  final String? avatarUrl;
}

class NotificationComment {
  NotificationComment.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      type = json['type'] as String?,
      content = json['content'] as String? ?? '';

  final String id;
  final String? type;
  final String content;
}

class NotificationReaction {
  NotificationReaction.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      type = json['type'] as String?,
      emoji = json['emoji'] as String? ?? '';

  final String id;
  final String? type;
  final String emoji;
}

class ReleaseEvent {
  ReleaseEvent.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      type = json['type'] as String,
      mediaType = json['mediaType'] as String,
      title = json['title'] as String? ?? '',
      unitTitle = json['unitTitle'] as String?,
      unitNumber = (json['unitNumber'] as num?)?.toInt(),
      containerNumber = (json['containerNumber'] as num?)?.toInt(),
      releaseAt = json['releaseAt'] as String?,
      anime = ReleaseMediaRef.fromJson(
        json['anime'],
        idKeys: const ['malId'],
        titleKey: 'title',
        coverKey: 'imageUrl',
      ),
      manga = ReleaseMediaRef.fromJson(
        json['manga'],
        idKeys: const ['anilistId', 'malId'],
        titleKey: 'title',
        coverKey: 'imageUrl',
      ),
      tvShow = ReleaseMediaRef.fromJson(
        json['tvShow'],
        idKeys: const ['tmdbId'],
        titleKey: 'name',
        coverKey: 'posterUrl',
      ),
      game = ReleaseMediaRef.fromJson(
        json['game'],
        idKeys: const ['igdbId'],
        titleKey: 'name',
        coverKey: 'coverUrl',
      );

  final String id;
  final String type;
  final String mediaType;
  final String title;
  final String? unitTitle;
  final int? unitNumber;
  final int? containerNumber;
  final String? releaseAt;
  final ReleaseMediaRef? anime;
  final ReleaseMediaRef? manga;
  final ReleaseMediaRef? tvShow;
  final ReleaseMediaRef? game;

  ReleaseMediaRef? get media => anime ?? manga ?? tvShow ?? game;

  MediaType? get detailType => switch (mediaType) {
    'Anime' => MediaType.anime,
    'Manga' => MediaType.manga,
    'TvShow' => MediaType.tv,
    'Game' => MediaType.game,
    _ => null,
  };
}

class ReleaseMediaRef {
  ReleaseMediaRef._(
    this.internalId,
    this.providerId,
    this.title,
    this.coverUrl,
  );

  static ReleaseMediaRef? fromJson(
    Object? json, {
    required List<String> idKeys,
    required String titleKey,
    required String coverKey,
  }) {
    if (json is! Map<String, dynamic>) return null;
    final internalId = json['id'] as String?;
    int? providerId;
    for (final key in idKeys) {
      final value = json[key];
      if (value is num) {
        providerId = value.toInt();
        break;
      }
    }
    return ReleaseMediaRef._(
      internalId,
      providerId,
      json[titleKey] as String?,
      json[coverKey] as String?,
    );
  }

  final String? internalId;
  final int? providerId;
  final String? title;
  final String? coverUrl;

  String? get detailId => (providerId?.toString().isNotEmpty ?? false)
      ? providerId.toString()
      : internalId;
}
