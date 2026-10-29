export 'watch_providers.dart';

class TvCastCredit {
  const TvCastCredit({
    required this.id,
    required this.name,
    required this.character,
    this.profileUrl,
    this.slug,
  });

  factory TvCastCredit.fromJson(Map<String, dynamic> json) => TvCastCredit(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: json['name'] as String? ?? '',
    character: json['character'] as String? ?? '',
    profileUrl: json['profileUrl'] as String?,
    slug: json['slug'] as String?,
  );

  final int id;
  final String name;
  final String character;
  final String? profileUrl;
  final String? slug;
}

class TvPersonRef {
  const TvPersonRef({
    required this.id,
    required this.name,
    this.profileUrl,
    this.slug,
  });

  factory TvPersonRef.fromJson(Map<String, dynamic> json) => TvPersonRef(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: json['name'] as String? ?? '',
    profileUrl: json['profileUrl'] as String?,
    slug: json['slug'] as String?,
  );

  final int id;
  final String name;
  final String? profileUrl;
  final String? slug;
}

class TvCompanyRef {
  const TvCompanyRef({
    required this.id,
    required this.name,
    this.logoUrl,
    this.originCountry,
  });

  factory TvCompanyRef.fromJson(Map<String, dynamic> json) => TvCompanyRef(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: json['name'] as String? ?? '',
    logoUrl: json['logoUrl'] as String?,
    originCountry: json['originCountry'] as String?,
  );

  final int id;
  final String name;
  final String? logoUrl;
  final String? originCountry;
}

class TvStatBucket {
  const TvStatBucket({required this.count, required this.percentage});

  factory TvStatBucket.fromJson(Map<String, dynamic> json) => TvStatBucket(
    count: (json['count'] as num?)?.toInt() ?? 0,
    percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
  );

  final int count;
  final double percentage;
}

class TvProgressStats {
  const TvProgressStats({
    required this.planToWatch,
    required this.watching,
    required this.completed,
    required this.dropped,
  });

  factory TvProgressStats.fromJson(Map<String, dynamic> json) =>
      TvProgressStats(
        planToWatch: TvStatBucket.fromJson(
          json['planToWatch'] as Map<String, dynamic>? ?? const {},
        ),
        watching: TvStatBucket.fromJson(
          json['watching'] as Map<String, dynamic>? ?? const {},
        ),
        completed: TvStatBucket.fromJson(
          json['completed'] as Map<String, dynamic>? ?? const {},
        ),
        dropped: TvStatBucket.fromJson(
          json['dropped'] as Map<String, dynamic>? ?? const {},
        ),
      );

  final TvStatBucket planToWatch;
  final TvStatBucket watching;
  final TvStatBucket completed;
  final TvStatBucket dropped;
}

class TvShowProgress {
  const TvShowProgress({
    required this.id,
    required this.status,
    this.watchCount,
    this.notes,
    this.startedAt,
    this.completedAt,
  });

  factory TvShowProgress.fromJson(Map<String, dynamic> json) => TvShowProgress(
    id: json['id'] as String,
    status: json['status'] as String? ?? '',
    watchCount: (json['watchCount'] as num?)?.toInt(),
    notes: json['notes'] as String?,
    startedAt: json['startedAt'] as String?,
    completedAt: json['completedAt'] as String?,
  );

  final String id;
  final String status;
  final int? watchCount;
  final String? notes;
  final String? startedAt;
  final String? completedAt;
}

class TvSeason {
  const TvSeason({
    required this.id,
    required this.name,
    required this.seasonNumber,
    required this.numberOfEpisodes,
    this.airDate,
    this.posterUrl,
  });

  factory TvSeason.fromJson(Map<String, dynamic> json) => TvSeason(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: json['name'] as String? ?? '',
    seasonNumber: (json['seasonNumber'] as num?)?.toInt() ?? 0,
    numberOfEpisodes: (json['numberOfEpisodes'] as num?)?.toInt() ?? 0,
    airDate: json['airDate'] as String?,
    posterUrl: json['posterUrl'] as String?,
  );

  final int id;
  final String name;
  final int seasonNumber;
  final int numberOfEpisodes;
  final String? airDate;
  final String? posterUrl;
}

class TvSeasonEpisode {
  const TvSeasonEpisode({
    required this.seasonNumber,
    required this.episodeNumber,
    required this.name,
    this.overview,
    this.airDate,
    this.stillUrl,
  });

  factory TvSeasonEpisode.fromJson(Map<String, dynamic> json) =>
      TvSeasonEpisode(
        seasonNumber: (json['seasonNumber'] as num?)?.toInt() ?? 0,
        episodeNumber: (json['episodeNumber'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        overview: json['overview'] as String?,
        airDate: json['airDate'] as String?,
        stillUrl: json['stillUrl'] as String?,
      );

  final int seasonNumber;
  final int episodeNumber;
  final String name;
  final String? overview;
  final String? airDate;
  final String? stillUrl;
}

class TvEpisodeWatch {
  const TvEpisodeWatch({
    required this.season,
    required this.episode,
    required this.status,
  });

  factory TvEpisodeWatch.fromJson(Map<String, dynamic> json) => TvEpisodeWatch(
    season: (json['season'] as num?)?.toInt() ?? 0,
    episode: (json['episode'] as num?)?.toInt() ?? 0,
    status: json['status'] as String? ?? '',
  );

  final int season;
  final int episode;
  final String status;
}

class TvShowDetail {
  const TvShowDetail({
    required this.id,
    required this.tmdbId,
    required this.name,
    this.originalName,
    this.tagline,
    this.overview,
    this.firstAirDate,
    this.lastAirDate,
    this.numberOfSeasons,
    this.numberOfEpisodes,
    this.episodeRuntime = const [],
    this.type,
    this.originalLanguage,
    this.homepage,
    this.inProduction,
    this.status,
    this.posterUrl,
    this.backdropUrl,
    this.genres = const [],
    this.productionCompanies = const [],
    this.cast = const [],
    this.createdBy = const [],
    this.trailerId,
    this.external,
    this.backdrops = const [],
    this.isAdult = false,
    this.tmdbReviewScore,
    this.popularity,
    this.lastRefreshedAt,
    this.tgReviewScore = 0,
    this.progressStats,
  });

  factory TvShowDetail.fromJson(Map<String, dynamic> json) => TvShowDetail(
    id: json['id'] as String,
    tmdbId: (json['tmdbId'] as num?)?.toInt() ?? 0,
    name: json['name'] as String? ?? '',
    originalName: json['originalName'] as String?,
    tagline: json['tagline'] as String?,
    overview: json['overview'] as String?,
    firstAirDate: json['firstAirDate'] as String?,
    lastAirDate: json['lastAirDate'] as String?,
    numberOfSeasons: (json['numberOfSeasons'] as num?)?.toInt(),
    numberOfEpisodes: (json['numberOfEpisodes'] as num?)?.toInt(),
    episodeRuntime: [
      for (final r in json['episodeRuntime'] as List? ?? const [])
        if (r is num) r.toInt(),
    ],
    type: json['type'] as String?,
    originalLanguage: json['originalLanguage'] as String?,
    homepage: json['homepage'] as String?,
    inProduction: json['inProduction'] as bool?,
    status: json['status'] as String?,
    posterUrl: json['posterUrl'] as String?,
    backdropUrl: json['backdropUrl'] as String?,
    genres: [
      for (final g in json['genres'] as List? ?? const [])
        if (g is String)
          g
        else if (g is Map && g['name'] is String)
          '${g['name']}',
    ],
    productionCompanies: [
      for (final c in json['productionCompanies'] as List? ?? const [])
        if (c is Map<String, dynamic>) TvCompanyRef.fromJson(c),
    ],
    cast: [
      for (final c in json['cast'] as List? ?? const [])
        if (c is Map<String, dynamic>) TvCastCredit.fromJson(c),
    ],
    createdBy: [
      for (final c in json['createdBy'] as List? ?? const [])
        if (c is Map<String, dynamic>) TvPersonRef.fromJson(c),
    ],
    trailerId: json['trailerId'] as String?,
    external: json['external'] is Map<String, dynamic>
        ? json['external'] as Map<String, dynamic>
        : null,
    backdrops: [for (final b in json['backdrops'] as List? ?? const []) '$b'],
    isAdult: json['isAdult'] as bool? ?? false,
    tmdbReviewScore: (json['tmdbReviewScore'] as num?)?.toDouble(),
    popularity: (json['popularity'] as num?)?.toDouble(),
    lastRefreshedAt: DateTime.tryParse('${json['lastRefreshedAt'] ?? ''}'),
    tgReviewScore: (json['tgReviewScore'] as num?)?.toDouble() ?? 0,
    progressStats: json['progressStats'] is Map<String, dynamic>
        ? TvProgressStats.fromJson(
            json['progressStats'] as Map<String, dynamic>,
          )
        : null,
  );

  final String id;
  final int tmdbId;
  final String name;
  final String? originalName;
  final String? tagline;
  final String? overview;
  final String? firstAirDate;
  final String? lastAirDate;
  final int? numberOfSeasons;
  final int? numberOfEpisodes;
  final List<int> episodeRuntime;
  final String? type;
  final String? originalLanguage;
  final String? homepage;
  final bool? inProduction;
  final String? status;
  final String? posterUrl;
  final String? backdropUrl;
  final List<String> genres;
  final List<TvCompanyRef> productionCompanies;
  final List<TvCastCredit> cast;
  final List<TvPersonRef> createdBy;
  final String? trailerId;
  final Map<String, dynamic>? external;
  final List<String> backdrops;
  final bool isAdult;
  final double? tmdbReviewScore;
  final double? popularity;
  final DateTime? lastRefreshedAt;
  final double tgReviewScore;
  final TvProgressStats? progressStats;

  String? get imdbId {
    final value = external?['imdb_id'];
    return value is String && value.isNotEmpty ? value : null;
  }
}
