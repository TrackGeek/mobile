class PsnProfile {
  const PsnProfile({required this.onlineId, this.avatarUrl});

  factory PsnProfile.fromJson(Map<String, dynamic> json) => PsnProfile(
    onlineId: json['onlineId'] as String? ?? '',
    avatarUrl: json['avatarUrl'] as String?,
  );

  final String onlineId;
  final String? avatarUrl;
}

class PsnTrophyCounts {
  const PsnTrophyCounts({
    required this.platinum,
    required this.gold,
    required this.silver,
    required this.bronze,
  });

  factory PsnTrophyCounts.fromJson(Map<String, dynamic> json) =>
      PsnTrophyCounts(
        platinum: (json['platinum'] as num?)?.toInt() ?? 0,
        gold: (json['gold'] as num?)?.toInt() ?? 0,
        silver: (json['silver'] as num?)?.toInt() ?? 0,
        bronze: (json['bronze'] as num?)?.toInt() ?? 0,
      );

  static const empty = PsnTrophyCounts(
    platinum: 0,
    gold: 0,
    silver: 0,
    bronze: 0,
  );

  final int platinum;
  final int gold;
  final int silver;
  final int bronze;

  int of(PsnTrophyGrade grade) => switch (grade) {
    PsnTrophyGrade.platinum => platinum,
    PsnTrophyGrade.gold => gold,
    PsnTrophyGrade.silver => silver,
    PsnTrophyGrade.bronze => bronze,
  };
}

enum PsnTrophyGrade { platinum, gold, silver, bronze }

class PsnTrophySummary {
  const PsnTrophySummary({
    required this.level,
    required this.progress,
    required this.earnedTrophies,
  });

  factory PsnTrophySummary.fromJson(Map<String, dynamic> json) {
    final earned = json['earnedTrophies'];
    return PsnTrophySummary(
      level: (json['level'] as num?)?.toInt() ?? 0,
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      earnedTrophies: earned is Map<String, dynamic>
          ? PsnTrophyCounts.fromJson(earned)
          : PsnTrophyCounts.empty,
    );
  }

  final int level;
  final int progress;
  final PsnTrophyCounts earnedTrophies;
}

class PsnTrophyTitle {
  const PsnTrophyTitle({
    required this.npCommunicationId,
    required this.name,
    required this.iconUrl,
    required this.platforms,
    required this.progress,
    required this.earnedTrophies,
    this.lastUpdatedAt,
  });

  factory PsnTrophyTitle.fromJson(Map<String, dynamic> json) {
    final earned = json['earnedTrophies'];
    return PsnTrophyTitle(
      npCommunicationId: json['npCommunicationId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      iconUrl: json['iconUrl'] as String? ?? '',
      platforms: [
        for (final platform in '${json['platform'] ?? ''}'.split(','))
          if (platform.trim().isNotEmpty) platform.trim(),
      ],
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      earnedTrophies: earned is Map<String, dynamic>
          ? PsnTrophyCounts.fromJson(earned)
          : PsnTrophyCounts.empty,
      lastUpdatedAt: DateTime.tryParse('${json['lastUpdatedAt'] ?? ''}'),
    );
  }

  final String npCommunicationId;
  final String name;
  final String iconUrl;
  final List<String> platforms;
  final int progress;
  final PsnTrophyCounts earnedTrophies;
  final DateTime? lastUpdatedAt;
}

class PsnTrophies {
  const PsnTrophies({
    required this.linked,
    required this.expired,
    this.profile,
    this.summary,
    this.recentTitles = const [],
    this.updatedAt,
  });

  factory PsnTrophies.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'];
    final summary = json['summary'];
    return PsnTrophies(
      linked: json['linked'] == true,
      expired: json['expired'] == true,
      profile: profile is Map<String, dynamic>
          ? PsnProfile.fromJson(profile)
          : null,
      summary: summary is Map<String, dynamic>
          ? PsnTrophySummary.fromJson(summary)
          : null,
      recentTitles: [
        for (final title in json['recentTitles'] as List? ?? const [])
          if (title is Map<String, dynamic>) PsnTrophyTitle.fromJson(title),
      ],
      updatedAt: DateTime.tryParse('${json['updatedAt'] ?? ''}'),
    );
  }

  final bool linked;
  final bool expired;
  final PsnProfile? profile;
  final PsnTrophySummary? summary;
  final List<PsnTrophyTitle> recentTitles;
  final DateTime? updatedAt;
}

class PsnAccount {
  const PsnAccount({
    required this.onlineId,
    this.avatarUrl,
    required this.expired,
  });

  factory PsnAccount.fromJson(Map<String, dynamic> json) => PsnAccount(
    onlineId: json['onlineId'] as String? ?? '',
    avatarUrl: json['avatarUrl'] as String?,
    expired: json['expired'] == true,
  );

  final String onlineId;
  final String? avatarUrl;
  final bool expired;
}
