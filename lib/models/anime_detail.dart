class AnimeTitle {
  const AnimeTitle({required this.type, required this.title});

  final String type;
  final String title;

  factory AnimeTitle.fromJson(Map<String, dynamic> json) => AnimeTitle(
    type: '${json['type'] ?? ''}',
    title: '${json['title'] ?? ''}',
  );
}

class AnimeCompanyRef {
  const AnimeCompanyRef({required this.malId, required this.name});

  final int malId;
  final String name;

  factory AnimeCompanyRef.fromJson(Map<String, dynamic> json) =>
      AnimeCompanyRef(
        malId: (json['malId'] as num?)?.toInt() ?? 0,
        name: '${json['name'] ?? ''}',
      );
}

class AnimeVoiceActor {
  const AnimeVoiceActor({
    required this.malId,
    required this.name,
    required this.language,
    this.imageUrl,
    this.slug,
  });

  final int malId;
  final String name;
  final String language;
  final String? imageUrl;
  final String? slug;

  factory AnimeVoiceActor.fromJson(Map<String, dynamic> json) =>
      AnimeVoiceActor(
        malId: (json['malId'] as num?)?.toInt() ?? 0,
        name: '${json['name'] ?? ''}',
        language: '${json['language'] ?? ''}',
        imageUrl: json['imageUrl'] as String?,
        slug: json['slug'] as String?,
      );
}

class AnimeCharacter {
  const AnimeCharacter({
    required this.malId,
    required this.name,
    required this.role,
    this.imageUrl,
    this.voiceActors = const [],
  });

  final int malId;
  final String name;
  final String role;
  final String? imageUrl;
  final List<AnimeVoiceActor> voiceActors;

  factory AnimeCharacter.fromJson(Map<String, dynamic> json) => AnimeCharacter(
    malId: (json['malId'] as num?)?.toInt() ?? 0,
    name: '${json['name'] ?? ''}',
    role: '${json['role'] ?? ''}',
    imageUrl: json['imageUrl'] as String?,
    voiceActors: [
      for (final v in json['voiceActors'] as List? ?? const [])
        if (v is Map<String, dynamic>) AnimeVoiceActor.fromJson(v),
    ],
  );
}

class AnimeCastMember {
  const AnimeCastMember({
    required this.malId,
    required this.name,
    this.imageUrl,
    this.positions = const [],
    this.slug,
  });

  final int malId;
  final String name;
  final String? imageUrl;
  final List<String> positions;
  final String? slug;

  factory AnimeCastMember.fromJson(Map<String, dynamic> json) =>
      AnimeCastMember(
        malId: (json['malId'] as num?)?.toInt() ?? 0,
        name: '${json['name'] ?? ''}',
        imageUrl: json['imageUrl'] as String?,
        positions: [
          for (final p in json['positions'] as List? ?? const []) '$p',
        ],
        slug: json['slug'] as String?,
      );
}

class AnimeRelationEntry {
  const AnimeRelationEntry({
    required this.malId,
    required this.title,
    required this.type,
    this.imageUrl,
  });

  final int malId;
  final String title;
  final String type;
  final String? imageUrl;

  factory AnimeRelationEntry.fromJson(Map<String, dynamic> json) =>
      AnimeRelationEntry(
        malId: (json['malId'] as num?)?.toInt() ?? 0,
        title: '${json['title'] ?? ''}',
        type: '${json['type'] ?? ''}',
        imageUrl: json['imageUrl'] as String?,
      );
}

class AnimeRelation {
  const AnimeRelation({required this.relationType, required this.entry});

  final String relationType;
  final List<AnimeRelationEntry> entry;

  factory AnimeRelation.fromJson(Map<String, dynamic> json) => AnimeRelation(
    relationType: '${json['relationType'] ?? ''}',
    entry: [
      for (final e in json['entry'] as List? ?? const [])
        if (e is Map<String, dynamic>) AnimeRelationEntry.fromJson(e),
    ],
  );
}

class AnimeEpisode {
  const AnimeEpisode({
    required this.malId,
    required this.title,
    required this.episodeNumber,
    this.imageUrl,
  });

  final int malId;
  final String title;
  final String episodeNumber;
  final String? imageUrl;

  factory AnimeEpisode.fromJson(Map<String, dynamic> json) => AnimeEpisode(
    malId: (json['malId'] as num?)?.toInt() ?? 0,
    title: '${json['title'] ?? ''}',
    episodeNumber: '${json['episodeNumber'] ?? ''}',
    imageUrl: json['imageUrl'] as String?,
  );
}

class AnimeExternalLink {
  const AnimeExternalLink({required this.name, required this.url});

  final String name;
  final String url;

  factory AnimeExternalLink.fromJson(Map<String, dynamic> json) =>
      AnimeExternalLink(
        name: '${json['name'] ?? ''}',
        url: '${json['url'] ?? ''}',
      );
}

class ProgressStat {
  const ProgressStat({required this.count, required this.percentage});

  final int count;
  final double percentage;

  factory ProgressStat.fromJson(Map<String, dynamic>? json) => ProgressStat(
    count: (json?['count'] as num?)?.toInt() ?? 0,
    percentage: (json?['percentage'] as num?)?.toDouble() ?? 0,
  );
}

class AnimeProgressStats {
  const AnimeProgressStats({
    required this.planToWatch,
    required this.watching,
    required this.completed,
    required this.dropped,
  });

  final ProgressStat planToWatch;
  final ProgressStat watching;
  final ProgressStat completed;
  final ProgressStat dropped;

  factory AnimeProgressStats.fromJson(
    Map<String, dynamic>? json,
  ) => AnimeProgressStats(
    planToWatch: ProgressStat.fromJson(
      json?['planToWatch'] as Map<String, dynamic>?,
    ),
    watching: ProgressStat.fromJson(json?['watching'] as Map<String, dynamic>?),
    completed: ProgressStat.fromJson(
      json?['completed'] as Map<String, dynamic>?,
    ),
    dropped: ProgressStat.fromJson(json?['dropped'] as Map<String, dynamic>?),
  );
}

class AnimeDetail {
  const AnimeDetail({
    required this.id,
    required this.malId,
    required this.title,
    this.synopsis,
    this.imageUrl,
    this.type,
    this.status,
    this.source,
    this.numberOfEpisodes,
    this.duration,
    this.broadcast,
    this.rating,
    this.season,
    this.year,
    this.airedFrom,
    this.tgReviewScore = 0,
    this.titles = const [],
    this.genres = const [],
    this.studios = const [],
    this.producers = const [],
    this.cast = const [],
    this.characters = const [],
    this.external = const [],
    this.trailerEmbedUrl,
    this.lastRefreshedAt,
    this.progressStats,
  });

  final String id;
  final int malId;
  final String title;
  final String? synopsis;
  final String? imageUrl;
  final String? type;
  final String? status;
  final String? source;
  final int? numberOfEpisodes;
  final String? duration;
  final String? broadcast;
  final String? rating;
  final String? season;
  final int? year;
  final String? airedFrom;
  final double tgReviewScore;
  final List<AnimeTitle> titles;
  final List<String> genres;
  final List<AnimeCompanyRef> studios;
  final List<AnimeCompanyRef> producers;
  final List<AnimeCastMember> cast;
  final List<AnimeCharacter> characters;
  final List<AnimeExternalLink> external;
  final String? trailerEmbedUrl;
  final DateTime? lastRefreshedAt;
  final AnimeProgressStats? progressStats;

  static List<AnimeCompanyRef> _companies(Object? value) => [
    for (final item in value as List? ?? const [])
      if (item is Map<String, dynamic>) AnimeCompanyRef.fromJson(item),
  ];

  factory AnimeDetail.fromJson(Map<String, dynamic> json) {
    final titles = <AnimeTitle>[
      for (final t in json['titles'] as List? ?? const [])
        if (t is Map<String, dynamic>) AnimeTitle.fromJson(t),
    ];
    final trailer = json['trailer'];
    return AnimeDetail(
      id: '${json['id']}',
      malId: (json['malId'] as num?)?.toInt() ?? 0,
      title: '${json['title'] ?? ''}',
      synopsis: json['synopsis'] as String?,
      imageUrl: json['imageUrl'] as String?,
      type: json['type'] as String?,
      status: json['status'] as String?,
      source: json['source'] as String?,
      numberOfEpisodes: (json['numberOfEpisodes'] as num?)?.toInt(),
      duration: json['duration'] as String?,
      broadcast: json['broadcast'] is Map<String, dynamic>
          ? (json['broadcast'] as Map)['string'] as String?
          : null,
      rating: json['rating'] as String?,
      season: json['season'] as String?,
      year: (json['year'] as num?)?.toInt(),
      airedFrom: json['airedFrom'] as String?,
      tgReviewScore: (json['tgReviewScore'] as num?)?.toDouble() ?? 0,
      titles: titles,
      genres: [for (final g in json['genres'] as List? ?? const []) '$g'],
      studios: _companies(json['studios']),
      producers: _companies(json['producers']),
      cast: [
        for (final c in json['cast'] as List? ?? const [])
          if (c is Map<String, dynamic>) AnimeCastMember.fromJson(c),
      ],
      characters: [
        for (final c in json['characters'] as List? ?? const [])
          if (c is Map<String, dynamic>) AnimeCharacter.fromJson(c),
      ],
      external: [
        for (final e in json['external'] as List? ?? const [])
          if (e is Map<String, dynamic>) AnimeExternalLink.fromJson(e),
      ],
      trailerEmbedUrl: trailer is Map<String, dynamic>
          ? trailer['embedUrl'] as String?
          : null,
      lastRefreshedAt: DateTime.tryParse('${json['lastRefreshedAt'] ?? ''}'),
      progressStats: json['progressStats'] is Map<String, dynamic>
          ? AnimeProgressStats.fromJson(
              json['progressStats'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  String? get englishTitle {
    for (final entry in titles) {
      if (entry.type == 'English') return entry.title;
    }
    return null;
  }

  List<AnimeTitle> get alternativeTitles {
    final seen = <String>{title.trim().toLowerCase()};
    return [
      for (final entry in titles)
        if (entry.title.trim().isNotEmpty &&
            seen.add(entry.title.trim().toLowerCase()))
          entry,
    ];
  }
}

class AnimeProgress {
  const AnimeProgress({
    required this.id,
    required this.status,
    this.watchCount,
    this.notes,
    this.startedAt,
    this.completedAt,
  });

  final String id;
  final String status;
  final int? watchCount;
  final String? notes;
  final String? startedAt;
  final String? completedAt;

  factory AnimeProgress.fromJson(Map<String, dynamic> json) => AnimeProgress(
    id: '${json['id']}',
    status: '${json['status'] ?? ''}',
    watchCount: (json['watchCount'] as num?)?.toInt(),
    notes: json['notes'] as String?,
    startedAt: json['startedAt'] as String?,
    completedAt: json['completedAt'] as String?,
  );
}

class AnimeEpisodeWatch {
  const AnimeEpisodeWatch({required this.episode, required this.status});

  final int episode;
  final String status;

  factory AnimeEpisodeWatch.fromJson(Map<String, dynamic> json) =>
      AnimeEpisodeWatch(
        episode: (json['episode'] as num?)?.toInt() ?? 0,
        status: '${json['status'] ?? ''}',
      );
}
