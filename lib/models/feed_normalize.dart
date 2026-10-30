import 'feed_entry.dart';
import 'media_type.dart';

class _ResolvedMedia {
  const _ResolvedMedia({
    required this.title,
    required this.cover,
    required this.slug,
    this.type,
    this.person = false,
    this.isAdult = false,
  });

  final String title;
  final String cover;
  final String slug;
  final MediaType? type;
  final bool person;
  final bool isAdult;
}

num _toNum(Object? value) => switch (value) {
  num n => n,
  String s => num.tryParse(s) ?? 0,
  _ => 0,
};

String? _slugOf(Object? preferred, Map<String, dynamic> media) =>
    '${preferred ?? media['id']}';

_ResolvedMedia? _mediaOf(MediaType type, Object? raw) {
  if (raw is! Map<String, dynamic>) return null;
  final isAdult = raw['isAdult'] as bool? ?? false;
  return switch (type) {
    MediaType.anime => _ResolvedMedia(
      title: raw['title'] as String? ?? '',
      cover: raw['imageUrl'] as String? ?? '',
      slug: _slugOf(raw['malId'], raw)!,
      type: type,
      isAdult: isAdult,
    ),
    MediaType.manga => _ResolvedMedia(
      title: raw['title'] as String? ?? '',
      cover: raw['imageUrl'] as String? ?? '',
      slug: _slugOf(raw['anilistId'] ?? raw['malId'], raw)!,
      type: type,
      isAdult: isAdult,
    ),
    MediaType.tv => _ResolvedMedia(
      title: raw['name'] as String? ?? '',
      cover: raw['posterUrl'] as String? ?? '',
      slug: _slugOf(raw['tmdbId'], raw)!,
      type: type,
      isAdult: isAdult,
    ),
    MediaType.movie => _ResolvedMedia(
      title: raw['title'] as String? ?? '',
      cover: raw['posterUrl'] as String? ?? '',
      slug: _slugOf(raw['tmdbId'], raw)!,
      type: type,
      isAdult: isAdult,
    ),
    MediaType.game => _ResolvedMedia(
      title: raw['name'] as String? ?? '',
      cover: raw['coverUrl'] as String? ?? '',
      slug: _slugOf(raw['igdbId'], raw)!,
      type: type,
      isAdult: isAdult,
    ),
    MediaType.book => _ResolvedMedia(
      title: raw['title'] as String? ?? '',
      cover: raw['imageUrl'] as String? ?? '',
      slug: _slugOf(raw['hardcoverId'], raw)!,
      type: type,
      isAdult: isAdult,
    ),
  };
}

_ResolvedMedia? _resolveMedia(Map<String, dynamic>? refs) {
  if (refs == null) return null;
  for (final type in MediaType.values) {
    final key = switch (type) {
      MediaType.tv => 'tvShow',
      _ => type.name,
    };
    final media = _mediaOf(type, refs[key]);
    if (media != null) return media;
  }
  final person = refs['person'];
  if (person is Map<String, dynamic>) {
    return _ResolvedMedia(
      title: person['name'] as String? ?? '',
      cover: person['imageUrl'] as String? ?? '',
      slug: _slugOf(person['slug'], person)!,
      person: true,
      isAdult: person['isAdult'] as bool? ?? false,
    );
  }
  return null;
}

const _reviewKeys = [
  'animeReview',
  'mangaReview',
  'tvShowReview',
  'movieReview',
  'gameReview',
  'bookReview',
];

const _progressKeys = [
  'animeProgress',
  'mangaProgress',
  'tvShowProgress',
  'movieProgress',
  'gameProgress',
  'bookProgress',
];

Map<String, dynamic>? _firstOf(
  Map<String, dynamic> activity,
  List<String> keys,
) {
  for (final key in keys) {
    final value = activity[key];
    if (value is Map<String, dynamic>) return value;
  }
  return null;
}

FeedProfile _profileOf(Map<String, dynamic> user) {
  final profile = user['profile'];
  return FeedProfile(
    name: (user['name'] as String?)?.isNotEmpty == true
        ? user['name'] as String
        : '${user['username']}',
    username: user['username'] as String?,
    avatarUrl: profile is Map<String, dynamic>
        ? profile['avatarUrl'] as String? ?? ''
        : '',
  );
}

FeedTitleLink _mediaLink(_ResolvedMedia media) => FeedMediaTitleLink(
  slug: media.slug,
  type: media.type,
  person: media.person,
);

FeedTitleLink _userLink(String username, String tab) =>
    FeedUserTitleLink(username: username, tab: tab);

FeedEntry? normalizeActivityGroup(Map<String, dynamic> group) {
  final items = group['items'];
  if (items is! List || items.isEmpty) return null;
  final activity = items.first;
  if (activity is! Map<String, dynamic>) return null;
  final user = activity['user'];
  if (user is! Map<String, dynamic>) return null;

  final type = '${group['type']}';
  final profile = _profileOf(user);
  final time = DateTime.tryParse('${group['createdAt']}') ?? DateTime(0);
  final count = activity['_count'];
  final rawReactions = activity['reactions'];
  final reactions = rawReactions is List
      ? rawReactions
            .whereType<Map<String, dynamic>>()
            .map(FeedReaction.fromJson)
            .toList()
      : <FeedReaction>[];
  final likes = count is Map<String, dynamic>
      ? (count['reactions'] as num?)?.toInt() ?? reactions.length
      : reactions.length;

  FeedEntry? base({
    required FeedEntryKind kind,
    required String titleKey,
    _ResolvedMedia? media,
    Map<String, Object>? titleValues,
    FeedTitleLink? titleLink,
    String? content,
    String? postId,
    String? authorId,
    bool isSpoiler = false,
    List<FeedScreenshot> screenshots = const [],
  }) => FeedEntry(
    kind: kind,
    profile: profile,
    activityType: type,
    coverUrl: media?.cover ?? '',
    titleKey: titleKey,
    titleValues: titleValues,
    titleLink: titleLink,
    mediaTitle: media?.title,
    content: content,
    time: time,
    likes: likes,
    media: media == null
        ? null
        : FeedMediaLink(
            slug: media.slug,
            type: media.type,
            person: media.person,
          ),
    activityId: activity['id'] as String?,
    reactions: reactions,
    postId: postId,
    authorId: authorId,
    isSpoiler: isSpoiler,
    isAdult: media?.isAdult ?? false,
    screenshots: screenshots,
  );

  return switch (type) {
    'ReviewAdded' => () {
      final review = _firstOf(activity, _reviewKeys);
      final media = _resolveMedia(review);
      if (review == null || media == null) return null;
      return base(
        kind: FeedEntryKind.review,
        titleKey: 'feed:reviewed',
        media: media,
        titleValues: {'content': media.title},
        titleLink: _mediaLink(media),
        content: review['summary'] as String?,
      );
    }(),
    'Watched' => () {
      final media = _resolveMedia({
        'anime': activity['anime'],
        'tvShow': activity['tvShow'],
      });
      final meta = activity['metadata'];
      if (media == null || meta is! Map<String, dynamic>) return null;
      final from = meta['from'];
      final to = meta['to'];
      if (from == null || to == null) return null;
      final season = meta['season'];
      final single = from == to;
      final titleKey = single
          ? season == null
                ? 'feed:watchedEpisodes'
                : 'feed:watchedEpisodesSeason'
          : season == null
          ? 'feed:watchedEpisodesRange'
          : 'feed:watchedEpisodesRangeSeason';
      return base(
        kind: FeedEntryKind.item,
        titleKey: titleKey,
        media: media,
        titleValues: {
          'content': media.title,
          if (single) 'episodeNumber': from else ...{'from': from, 'to': to},
          'season': ?season,
        },
        titleLink: _mediaLink(media),
      );
    }(),
    'ChaptersRead' => () {
      final media = _resolveMedia(
        activity['mangaProgress'] is Map<String, dynamic>
            ? activity['mangaProgress'] as Map<String, dynamic>
            : activity['bookProgress'] is Map<String, dynamic>
            ? activity['bookProgress'] as Map<String, dynamic>
            : null,
      );
      final meta = activity['metadata'];
      if (media == null || meta is! Map<String, dynamic>) return null;
      final from = meta['from'];
      final to = meta['to'];
      if (from == null || to == null) return null;
      final isBook = media.type == MediaType.book;
      final fromNum = _toNum(from);
      final toNum = _toNum(to);
      return base(
        kind: FeedEntryKind.item,
        titleKey: isBook
            ? 'feed:readProgress'
            : from == to
            ? 'feed:readChapter'
            : 'feed:readChapters',
        media: media,
        titleValues: isBook
            ? {
                'content': media.title,
                'unit': 'page',
                'range': from == to ? '$from' : '$from-$to',
                'count': toNum - fromNum + 1,
              }
            : {
                'content': media.title,
                'chapterNumber': from,
                'chapterNumberInitial': from,
                'chapterNumberEnd': to,
              },
        titleLink: _mediaLink(media),
      );
    }(),
    'ProgressStarted' ||
    'ProgressCompleted' ||
    'ProgressPaused' ||
    'ProgressDropped' ||
    'ProgressPlanned' => () {
      final progress = _firstOf(activity, _progressKeys);
      final media = _resolveMedia(progress);
      if (progress == null || media == null) return null;
      const trackingKeys = {
        'ProgressCompleted': 'feed:completedTracking',
        'ProgressPaused': 'feed:pausedTracking',
        'ProgressDropped': 'feed:droppedTracking',
        'ProgressPlanned': 'feed:plannedTracking',
      };
      return base(
        kind: FeedEntryKind.item,
        titleKey: trackingKeys[type] ?? 'feed:startedTracking',
        media: media,
        titleValues: {'content': media.title},
        titleLink: _mediaLink(media),
      );
    }(),
    'ScreenshotAdded' => () {
      final screenshots = [
        for (final item in items)
          if (item is Map<String, dynamic> &&
              item['gameScreenshot'] is Map<String, dynamic>)
            item['gameScreenshot'] as Map<String, dynamic>,
      ];
      if (screenshots.isEmpty) return null;
      final media = _resolveMedia({'game': screenshots.first['game']});
      if (media == null) return null;
      return base(
        kind: FeedEntryKind.screenshot,
        titleKey: 'feed:addScreenshots',
        media: media,
        titleValues: {'content': media.title, 'count': screenshots.length},
        titleLink: _mediaLink(media),
        screenshots: [
          for (final shot in screenshots)
            FeedScreenshot(
              id: '${shot['id']}',
              url: shot['url'] as String? ?? '',
              type: shot['type'] as String? ?? 'Image',
              description: shot['description'] as String?,
              isSpoiler: shot['isSpoiler'] as bool? ?? false,
            ),
        ],
      );
    }(),
    'PostCreated' => () {
      final post = activity['post'];
      if (post is! Map<String, dynamic>) return null;
      final media = _resolveMedia(post);
      return base(
        kind: FeedEntryKind.post,
        titleKey: media != null ? 'feed:postedAbout' : 'feed:posted',
        media: media,
        titleValues: media != null ? {'content': media.title} : null,
        titleLink: media != null ? _mediaLink(media) : null,
        content: post['content'] as String? ?? '',
        postId: post['id'] as String?,
        authorId: activity['userId'] as String?,
        isSpoiler: post['isSpoiler'] as bool? ?? false,
      );
    }(),
    'FavoriteAdded' => () {
      final media = _resolveMedia(
        activity['favorite'] is Map<String, dynamic>
            ? activity['favorite'] as Map<String, dynamic>
            : null,
      );
      if (media == null) return null;
      return base(
        kind: FeedEntryKind.item,
        titleKey: 'feed:favorited',
        media: media,
        titleValues: {'content': media.title},
        titleLink: _mediaLink(media),
      );
    }(),
    'ListItemAdded' => () {
      final media = _resolveMedia(
        activity['listItem'] is Map<String, dynamic>
            ? activity['listItem'] as Map<String, dynamic>
            : null,
      );
      if (media == null) return null;
      return base(
        kind: FeedEntryKind.item,
        titleKey: 'feed:addedToList',
        media: media,
        titleValues: {'content': media.title},
        titleLink: _mediaLink(media),
      );
    }(),
    'ListCreated' => () {
      final list = activity['list'];
      if (list is! Map<String, dynamic>) return null;
      return base(
        kind: FeedEntryKind.item,
        titleKey: 'feed:createdList',
        titleValues: {'content': '${list['name']}'},
        titleLink: profile.username != null
            ? _userLink(profile.username!, 'lists')
            : null,
      );
    }(),
    'Followed' => () {
      final following = activity['following'];
      if (following is! Map<String, dynamic>) return null;
      final target = following['following'];
      if (target is! Map<String, dynamic>) return null;
      final targetName = (target['name'] as String?)?.isNotEmpty == true
          ? target['name'] as String
          : '${target['username']}';
      final targetUsername = target['username'] as String?;
      return base(
        kind: FeedEntryKind.item,
        titleKey: 'feed:followed',
        titleValues: {'content': targetName},
        titleLink: targetUsername != null
            ? _userLink(targetUsername, 'overview')
            : null,
      );
    }(),
    'MedalEarned' => () {
      final userMedal = activity['userMedal'];
      if (userMedal is! Map<String, dynamic>) return null;
      final medal = userMedal['medal'];
      if (medal is! Map<String, dynamic>) return null;
      return base(
        kind: FeedEntryKind.item,
        titleKey: 'feed:earnedMedal',
        titleValues: {'content': '${medal['name']}'},
      );
    }(),
    'AccountCreated' => base(kind: FeedEntryKind.item, titleKey: 'feed:joined'),
    _ => null,
  };
}
