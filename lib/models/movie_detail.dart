export 'watch_providers.dart';

class MovieCastCredit {
  const MovieCastCredit({
    required this.id,
    required this.name,
    required this.character,
    this.profileUrl,
    this.slug,
  });

  factory MovieCastCredit.fromJson(Map<String, dynamic> json) =>
      MovieCastCredit(
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

class MovieCrewCredit {
  const MovieCrewCredit({
    required this.id,
    required this.name,
    required this.job,
    this.profileUrl,
    this.slug,
  });

  factory MovieCrewCredit.fromJson(Map<String, dynamic> json) =>
      MovieCrewCredit(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        job: json['job'] as String? ?? '',
        profileUrl: json['profileUrl'] as String?,
        slug: json['slug'] as String?,
      );

  final int id;
  final String name;
  final String job;
  final String? profileUrl;
  final String? slug;
}

class MovieCompanyRef {
  const MovieCompanyRef({
    required this.id,
    required this.name,
    this.logoUrl,
    this.originCountry,
  });

  factory MovieCompanyRef.fromJson(Map<String, dynamic> json) =>
      MovieCompanyRef(
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

class MovieSpokenLanguage {
  const MovieSpokenLanguage({
    required this.englishName,
    required this.name,
    required this.iso6391,
  });

  factory MovieSpokenLanguage.fromJson(Map<String, dynamic> json) =>
      MovieSpokenLanguage(
        englishName: json['englishName'] as String? ?? '',
        name: json['name'] as String? ?? '',
        iso6391: json['iso639_1'] as String? ?? '',
      );

  final String englishName;
  final String name;
  final String iso6391;
}

class MovieCollectionRef {
  const MovieCollectionRef({required this.id, required this.name});

  factory MovieCollectionRef.fromJson(Map<String, dynamic> json) =>
      MovieCollectionRef(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
      );

  final int id;
  final String name;
}

class MovieStatBucket {
  const MovieStatBucket({required this.count, required this.percentage});

  factory MovieStatBucket.fromJson(Map<String, dynamic> json) =>
      MovieStatBucket(
        count: (json['count'] as num?)?.toInt() ?? 0,
        percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      );

  final int count;
  final double percentage;
}

class MovieProgressStats {
  const MovieProgressStats({
    required this.planToWatch,
    required this.watching,
    required this.completed,
    required this.paused,
    required this.dropped,
  });

  factory MovieProgressStats.fromJson(Map<String, dynamic> json) =>
      MovieProgressStats(
        planToWatch: MovieStatBucket.fromJson(
          json['planToWatch'] as Map<String, dynamic>? ?? const {},
        ),
        watching: MovieStatBucket.fromJson(
          json['watching'] as Map<String, dynamic>? ?? const {},
        ),
        completed: MovieStatBucket.fromJson(
          json['completed'] as Map<String, dynamic>? ?? const {},
        ),
        paused: MovieStatBucket.fromJson(
          json['paused'] as Map<String, dynamic>? ?? const {},
        ),
        dropped: MovieStatBucket.fromJson(
          json['dropped'] as Map<String, dynamic>? ?? const {},
        ),
      );

  final MovieStatBucket planToWatch;
  final MovieStatBucket watching;
  final MovieStatBucket completed;
  final MovieStatBucket paused;
  final MovieStatBucket dropped;
}

class MovieProgress {
  const MovieProgress({
    required this.id,
    required this.status,
    this.watchCount,
    this.startedAt,
    this.completedAt,
  });

  factory MovieProgress.fromJson(Map<String, dynamic> json) => MovieProgress(
    id: json['id'] as String,
    status: json['status'] as String? ?? '',
    watchCount: (json['watchCount'] as num?)?.toInt(),
    startedAt: json['startedAt'] as String?,
    completedAt: json['completedAt'] as String?,
  );

  final String id;
  final String status;
  final int? watchCount;
  final String? startedAt;
  final String? completedAt;
}

class MovieFranchisePart {
  const MovieFranchisePart({
    required this.tmdbId,
    required this.title,
    this.isAdult = false,
    this.overview,
    this.releaseDate,
    this.posterUrl,
    this.backdropUrl,
    this.tmdbReviewScore,
    this.tgReviewScore = 0,
  });

  factory MovieFranchisePart.fromJson(Map<String, dynamic> json) =>
      MovieFranchisePart(
        tmdbId: (json['tmdbId'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
        isAdult: json['isAdult'] as bool? ?? false,
        overview: json['overview'] as String?,
        releaseDate: json['releaseDate'] as String?,
        posterUrl: json['posterUrl'] as String?,
        backdropUrl: json['backdropUrl'] as String?,
        tmdbReviewScore: (json['tmdbReviewScore'] as num?)?.toDouble(),
        tgReviewScore: (json['tgReviewScore'] as num?)?.toDouble() ?? 0,
      );

  final int tmdbId;
  final String title;
  final bool isAdult;
  final String? overview;
  final String? releaseDate;
  final String? posterUrl;
  final String? backdropUrl;
  final double? tmdbReviewScore;
  final double tgReviewScore;
}

class MovieFranchise {
  const MovieFranchise({
    required this.id,
    required this.name,
    required this.slug,
    this.overview,
    this.posterUrl,
    this.backdropUrl,
    required this.parts,
  });

  factory MovieFranchise.fromJson(Map<String, dynamic> json) => MovieFranchise(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: json['name'] as String? ?? '',
    slug: json['slug'] as String? ?? '',
    overview: json['overview'] as String?,
    posterUrl: json['posterUrl'] as String?,
    backdropUrl: json['backdropUrl'] as String?,
    parts: [
      for (final part in json['parts'] as List? ?? const [])
        if (part is Map<String, dynamic>) MovieFranchisePart.fromJson(part),
    ],
  );

  final int id;
  final String name;
  final String slug;
  final String? overview;
  final String? posterUrl;
  final String? backdropUrl;
  final List<MovieFranchisePart> parts;
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

class MovieDetail {
  const MovieDetail({
    required this.id,
    required this.tmdbId,
    this.imdbId,
    this.isAdult = false,
    this.tmdbReviewScore,
    this.budget = 0,
    this.revenue = 0,
    this.backdropUrl,
    this.belongsToCollection,
    this.homepage,
    this.originalLanguage,
    this.originalTitle,
    this.overview,
    this.genres = const [],
    this.popularity,
    this.posterUrl,
    required this.productionCompanies,
    required this.productionCountries,
    this.releaseDate,
    this.runtime,
    required this.spokenLanguages,
    this.status,
    required this.title,
    required this.cast,
    required this.crew,
    this.trailerId,
    this.external,
    required this.backdrops,
    this.lastRefreshedAt,
    this.tgReviewScore = 0,
    this.progressStats,
  });

  factory MovieDetail.fromJson(Map<String, dynamic> json) => MovieDetail(
    id: json['id'] as String,
    tmdbId: (json['tmdbId'] as num?)?.toInt() ?? 0,
    imdbId: json['imdbId'] as String?,
    isAdult: json['isAdult'] as bool? ?? false,
    tmdbReviewScore: (json['tmdbReviewScore'] as num?)?.toDouble(),
    budget: _toDouble(json['budget']),
    revenue: _toDouble(json['revenue']),
    backdropUrl: json['backdropUrl'] as String?,
    belongsToCollection: json['belongsToCollection'] is Map<String, dynamic>
        ? MovieCollectionRef.fromJson(
            json['belongsToCollection'] as Map<String, dynamic>,
          )
        : null,
    homepage: json['homepage'] as String?,
    originalLanguage: json['originalLanguage'] as String?,
    originalTitle: json['originalTitle'] as String?,
    overview: json['overview'] as String?,
    genres: [
      for (final g in json['genres'] as List? ?? const [])
        if (g is String)
          g
        else if (g is Map && g['name'] is String)
          '${g['name']}',
    ],
    popularity: (json['popularity'] as num?)?.toDouble(),
    posterUrl: json['posterUrl'] as String?,
    productionCompanies: [
      for (final c in json['productionCompanies'] as List? ?? const [])
        if (c is Map<String, dynamic>) MovieCompanyRef.fromJson(c),
    ],
    productionCountries: [
      for (final c in json['productionCountries'] as List? ?? const []) '$c',
    ],
    releaseDate: json['releaseDate'] as String?,
    runtime: (json['runtime'] as num?)?.toInt(),
    spokenLanguages: [
      for (final l in json['spokenLanguages'] as List? ?? const [])
        if (l is Map<String, dynamic>) MovieSpokenLanguage.fromJson(l),
    ],
    status: json['status'] as String?,
    title: json['title'] as String? ?? '',
    cast: [
      for (final c in json['cast'] as List? ?? const [])
        if (c is Map<String, dynamic>) MovieCastCredit.fromJson(c),
    ],
    crew: [
      for (final c in json['crew'] as List? ?? const [])
        if (c is Map<String, dynamic>) MovieCrewCredit.fromJson(c),
    ],
    trailerId: json['trailerId'] as String?,
    external: json['external'] is Map<String, dynamic>
        ? json['external'] as Map<String, dynamic>
        : null,
    backdrops: [for (final b in json['backdrops'] as List? ?? const []) '$b'],
    lastRefreshedAt: DateTime.tryParse('${json['lastRefreshedAt'] ?? ''}'),
    tgReviewScore: (json['tgReviewScore'] as num?)?.toDouble() ?? 0,
    progressStats: json['progressStats'] is Map<String, dynamic>
        ? MovieProgressStats.fromJson(
            json['progressStats'] as Map<String, dynamic>,
          )
        : null,
  );

  final String id;
  final int tmdbId;
  final String? imdbId;
  final bool isAdult;
  final double? tmdbReviewScore;
  final double budget;
  final double revenue;
  final String? backdropUrl;
  final MovieCollectionRef? belongsToCollection;
  final String? homepage;
  final String? originalLanguage;
  final String? originalTitle;
  final String? overview;
  final List<String> genres;
  final double? popularity;
  final String? posterUrl;
  final List<MovieCompanyRef> productionCompanies;
  final List<String> productionCountries;
  final String? releaseDate;
  final int? runtime;
  final List<MovieSpokenLanguage> spokenLanguages;
  final String? status;
  final String title;
  final List<MovieCastCredit> cast;
  final List<MovieCrewCredit> crew;
  final String? trailerId;
  final Map<String, dynamic>? external;
  final List<String> backdrops;
  final DateTime? lastRefreshedAt;
  final double tgReviewScore;
  final MovieProgressStats? progressStats;

  List<MovieCrewCredit> get directors => [
    for (final member in crew)
      if (member.job == 'Director') member,
  ];
}
