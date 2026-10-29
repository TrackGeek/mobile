import 'media_type.dart';

class SetupPhoto {
  const SetupPhoto({required this.id, required this.url});

  final String id;
  final String url;

  factory SetupPhoto.fromJson(Map<String, dynamic> json) =>
      SetupPhoto(id: '${json['id']}', url: '${json['url'] ?? ''}');
}

class SetupItem {
  const SetupItem({
    required this.id,
    required this.type,
    this.name,
    this.brand,
    this.link,
  });

  final String id;
  final String type;
  final String? name;
  final String? brand;
  final String? link;

  factory SetupItem.fromJson(Map<String, dynamic> json) => SetupItem(
    id: '${json['id']}',
    type: '${json['type'] ?? 'COMPONENT'}',
    name: json['name'] as String?,
    brand: json['brand'] as String?,
    link: json['link'] as String?,
  );
}

class ProfileLink {
  const ProfileLink({required this.id, required this.label, required this.url});

  final String id;
  final String label;
  final String url;

  factory ProfileLink.fromJson(Map<String, dynamic> json) => ProfileLink(
    id: '${json['id']}',
    label: '${json['label'] ?? ''}',
    url: '${json['url'] ?? ''}',
  );
}

class UserProfileDetails {
  const UserProfileDetails({
    required this.id,
    this.color,
    this.avatarFrame,
    this.title,
    this.bannerEffect,
    this.about = '',
    this.bannerUrl,
    this.avatarUrl,
    this.setupPhotos = const [],
    this.setupItems = const [],
    this.links = const [],
  });

  final String id;
  final String? color;
  final String? avatarFrame;
  final String? title;
  final String? bannerEffect;
  final String about;
  final String? bannerUrl;
  final String? avatarUrl;
  final List<SetupPhoto> setupPhotos;
  final List<SetupItem> setupItems;
  final List<ProfileLink> links;

  factory UserProfileDetails.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) decode) => [
      for (final item in json[key] as List? ?? const [])
        if (item is Map<String, dynamic>) decode(item),
    ];
    return UserProfileDetails(
      id: '${json['id']}',
      color: json['color'] as String?,
      avatarFrame: json['avatarFrame'] as String?,
      title: json['title'] as String?,
      bannerEffect: json['bannerEffect'] as String?,
      about: json['about'] as String? ?? '',
      bannerUrl: json['bannerUrl'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      setupPhotos: list('setupPhotos', SetupPhoto.fromJson),
      setupItems: list('setupItems', SetupItem.fromJson),
      links: list('links', ProfileLink.fromJson),
    );
  }
}

class LevelProgress {
  const LevelProgress({
    required this.level,
    required this.totalXp,
    required this.currentLevelXp,
    required this.nextLevelXp,
    required this.percentage,
  });

  final int level;
  final int totalXp;
  final int currentLevelXp;
  final int nextLevelXp;
  final double percentage;

  factory LevelProgress.fromJson(Map<String, dynamic> json) => LevelProgress(
    level: (json['level'] as num?)?.toInt() ?? 0,
    totalXp: (json['totalXp'] as num?)?.toInt() ?? 0,
    currentLevelXp: (json['currentLevelXp'] as num?)?.toInt() ?? 0,
    nextLevelXp: (json['nextLevelXp'] as num?)?.toInt() ?? 0,
    percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
  );
}

class ContentLevelProgress extends LevelProgress {
  const ContentLevelProgress({
    required super.level,
    required super.totalXp,
    required super.currentLevelXp,
    required super.nextLevelXp,
    required super.percentage,
    required this.contentType,
  });

  final String contentType;

  factory ContentLevelProgress.fromJson(Map<String, dynamic> json) =>
      ContentLevelProgress(
        level: (json['level'] as num?)?.toInt() ?? 0,
        totalXp: (json['totalXp'] as num?)?.toInt() ?? 0,
        currentLevelXp: (json['currentLevelXp'] as num?)?.toInt() ?? 0,
        nextLevelXp: (json['nextLevelXp'] as num?)?.toInt() ?? 0,
        percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
        contentType: '${json['contentType'] ?? ''}',
      );
}

class XpSummary extends LevelProgress {
  const XpSummary({
    required super.level,
    required super.totalXp,
    required super.currentLevelXp,
    required super.nextLevelXp,
    required super.percentage,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.contentTypes = const [],
  });

  final int currentStreak;
  final int longestStreak;
  final List<ContentLevelProgress> contentTypes;

  static const empty = XpSummary(
    level: 0,
    totalXp: 0,
    currentLevelXp: 0,
    nextLevelXp: 0,
    percentage: 0,
  );

  factory XpSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return empty;
    return XpSummary(
      level: (json['level'] as num?)?.toInt() ?? 0,
      totalXp: (json['totalXp'] as num?)?.toInt() ?? 0,
      currentLevelXp: (json['currentLevelXp'] as num?)?.toInt() ?? 0,
      nextLevelXp: (json['nextLevelXp'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
      contentTypes: [
        for (final entry in json['contentTypes'] as List? ?? const [])
          if (entry is Map<String, dynamic>)
            ContentLevelProgress.fromJson(entry),
      ],
    );
  }
}

class StatusStat {
  const StatusStat({required this.count, required this.percentage});

  final int count;
  final double percentage;

  static const zero = StatusStat(count: 0, percentage: 0);

  factory StatusStat.fromJson(Map<String, dynamic>? json) => StatusStat(
    count: (json?['count'] as num?)?.toInt() ?? 0,
    percentage: (json?['percentage'] as num?)?.toDouble() ?? 0,
  );
}

class TypeProgressStats {
  const TypeProgressStats({required this.total, required this.byStatus});

  final int total;
  final Map<String, StatusStat> byStatus;

  factory TypeProgressStats.fromJson(Map<String, dynamic> json) {
    const statuses = [
      'watching',
      'reading',
      'playing',
      'completed',
      'paused',
      'dropped',
      'planning',
    ];
    return TypeProgressStats(
      total: (json['total'] as num?)?.toInt() ?? 0,
      byStatus: {
        for (final status in statuses)
          if (json[status] is Map<String, dynamic>)
            status: StatusStat.fromJson(json[status] as Map<String, dynamic>),
      },
    );
  }
}

class UserMedal {
  const UserMedal({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  final String id;
  final String name;
  final String imageUrl;

  factory UserMedal.fromJson(Map<String, dynamic> json) => UserMedal(
    id: '${json['id']}',
    name: '${json['name'] ?? ''}',
    imageUrl: '${json['imageUrl'] ?? ''}',
  );
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.username,
    required this.profile,
    required this.createdAt,
    this.tier,
    this.tierStartedAt,
    this.followers = 0,
    this.following = 0,
    this.userMedals = const [],
    this.progressStats = const {},
    this.reviewCount = 0,
    this.listCount = 0,
    this.favoriteCount = 0,
    this.screenshotCount = 0,
    this.latestReviewType,
    this.latestProgressType,
    this.latestFavoriteType,
    this.xp = XpSummary.empty,
    this.coinBalance = 0,
    this.missionsTotal = 0,
    this.missionsCompleted = 0,
  });

  final String id;
  final String name;
  final String username;
  final UserProfileDetails profile;
  final DateTime? createdAt;
  final String? tier;
  final String? tierStartedAt;
  final int followers;
  final int following;
  final List<UserMedal> userMedals;
  final Map<String, TypeProgressStats> progressStats;
  final int reviewCount;
  final int listCount;
  final int favoriteCount;
  final int screenshotCount;
  final MediaType? latestReviewType;
  final MediaType? latestProgressType;
  final String? latestFavoriteType;
  final XpSummary xp;
  final int coinBalance;
  final int missionsTotal;
  final int missionsCompleted;

  int get totalProgress =>
      progressStats.values.fold(0, (sum, stats) => sum + stats.total);

  static MediaType? _reviewType(Object? value) {
    for (final type in MediaType.values) {
      if (type.name == value) return type;
    }
    return null;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final stats = <String, TypeProgressStats>{};
    final rawStats = json['progressStats'];
    if (rawStats is Map<String, dynamic>) {
      for (final entry in rawStats.entries) {
        if (entry.value is Map<String, dynamic>) {
          stats[entry.key] = TypeProgressStats.fromJson(
            entry.value as Map<String, dynamic>,
          );
        }
      }
    }
    final counts = json['counts'];
    final missions = json['missions'];
    return UserProfile(
      id: '${json['id']}',
      name: '${json['name'] ?? ''}',
      username: '${json['username'] ?? ''}',
      profile: UserProfileDetails.fromJson(
        json['profile'] is Map<String, dynamic>
            ? json['profile'] as Map<String, dynamic>
            : const {},
      ),
      createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}'),
      tier: json['tier'] as String?,
      tierStartedAt: json['tierStartedAt'] as String?,
      followers: json['_count'] is Map<String, dynamic>
          ? ((json['_count'] as Map)['followers'] as num?)?.toInt() ?? 0
          : 0,
      following: json['_count'] is Map<String, dynamic>
          ? ((json['_count'] as Map)['following'] as num?)?.toInt() ?? 0
          : 0,
      userMedals: [
        for (final entry in json['userMedals'] as List? ?? const [])
          if (entry is Map<String, dynamic> &&
              entry['medal'] is Map<String, dynamic>)
            UserMedal.fromJson(entry['medal'] as Map<String, dynamic>),
      ],
      progressStats: stats,
      reviewCount: counts is Map<String, dynamic>
          ? (counts['reviews'] as num?)?.toInt() ?? 0
          : 0,
      listCount: counts is Map<String, dynamic>
          ? (counts['lists'] as num?)?.toInt() ?? 0
          : 0,
      favoriteCount: counts is Map<String, dynamic>
          ? (counts['favorites'] as num?)?.toInt() ?? 0
          : 0,
      screenshotCount: counts is Map<String, dynamic>
          ? (counts['screenshots'] as num?)?.toInt() ?? 0
          : 0,
      latestReviewType: _reviewType(json['latestReviewType']),
      latestProgressType: _reviewType(json['latestProgressType']),
      latestFavoriteType: json['latestFavoriteType'] as String?,
      xp: XpSummary.fromJson(json['xp'] as Map<String, dynamic>?),
      coinBalance: json['coins'] is Map<String, dynamic>
          ? ((json['coins'] as Map)['balance'] as num?)?.toInt() ?? 0
          : 0,
      missionsTotal: missions is Map<String, dynamic>
          ? (missions['total'] as num?)?.toInt() ?? 0
          : 0,
      missionsCompleted: missions is Map<String, dynamic>
          ? (missions['completed'] as num?)?.toInt() ?? 0
          : 0,
    );
  }
}
