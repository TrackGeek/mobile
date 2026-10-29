import 'media_type.dart';

enum PersonSource { tmdb, mal, anilist }

class PersonCredit {
  const PersonCredit({
    required this.key,
    required this.mediaType,
    required this.id,
    required this.title,
    this.imageUrl,
    this.backdropUrl,
    this.releaseDate,
    this.year,
    required this.roles,
    required this.isCast,
    required this.isAdult,
    this.episodeCount,
    this.externalReviewScore,
    this.popularity,
    required this.tgReviewScore,
    required this.isTracked,
  });

  factory PersonCredit.fromJson(Map<String, dynamic> json) => PersonCredit(
    key: json['key'] as String,
    mediaType: MediaType.values.byName(json['mediaType'] as String),
    id: json['id'] as int,
    title: json['title'] as String,
    imageUrl: json['imageUrl'] as String?,
    backdropUrl: json['backdropUrl'] as String?,
    releaseDate: json['releaseDate'] as String?,
    year: json['year'] as int?,
    roles: [for (final role in json['roles'] as List<dynamic>) role as String],
    isCast: json['isCast'] as bool,
    isAdult: json['isAdult'] as bool? ?? false,
    episodeCount: json['episodeCount'] as int?,
    externalReviewScore: (json['externalReviewScore'] as num?)?.toDouble(),
    popularity: (json['popularity'] as num?)?.toDouble(),
    tgReviewScore: (json['tgReviewScore'] as num?)?.toDouble() ?? 0,
    isTracked: json['isTracked'] as bool? ?? false,
  );

  final String key;
  final MediaType mediaType;
  final int id;
  final String title;
  final String? imageUrl;
  final String? backdropUrl;
  final String? releaseDate;
  final int? year;
  final List<String> roles;
  final bool isCast;
  final bool isAdult;
  final int? episodeCount;
  final double? externalReviewScore;
  final double? popularity;
  final double tgReviewScore;
  final bool isTracked;
}

class PersonStats {
  const PersonStats({
    required this.total,
    required this.movies,
    required this.tvShows,
    required this.anime,
    this.manga,
    required this.tracked,
  });

  factory PersonStats.fromJson(Map<String, dynamic> json) => PersonStats(
    total: json['total'] as int,
    movies: json['movies'] as int? ?? 0,
    tvShows: json['tvShows'] as int? ?? 0,
    anime: json['anime'] as int? ?? 0,
    manga: json['manga'] as int?,
    tracked: json['tracked'] as int? ?? 0,
  );

  final int total;
  final int movies;
  final int tvShows;
  final int anime;
  final int? manga;
  final int tracked;
}

class Person {
  const Person({
    required this.id,
    required this.slug,
    required this.name,
    this.tmdbId,
    this.malId,
    this.anilistId,
    this.imageUrl,
    this.biography,
    this.birthday,
    this.deathday,
    this.placeOfBirth,
    this.knownForDepartment,
    required this.alsoKnownAs,
    this.gender,
    this.homepage,
    this.popularity,
    required this.images,
    this.external,
    required this.source,
    required this.credits,
    required this.stats,
  });

  factory Person.fromJson(Map<String, dynamic> json) => Person(
    id: json['id'] as String,
    slug: json['slug'] as String,
    name: json['name'] as String,
    tmdbId: json['tmdbId'] as int?,
    malId: json['malId'] as int?,
    anilistId: json['anilistId'] as int?,
    imageUrl: json['imageUrl'] as String?,
    biography: json['biography'] as String?,
    birthday: json['birthday'] as String?,
    deathday: json['deathday'] as String?,
    placeOfBirth: json['placeOfBirth'] as String?,
    knownForDepartment: json['knownForDepartment'] as String?,
    alsoKnownAs: [
      for (final alias in json['alsoKnownAs'] as List<dynamic>? ?? const [])
        alias as String,
    ],
    gender: json['gender'] as int?,
    homepage: json['homepage'] as String?,
    popularity: (json['popularity'] as num?)?.toDouble(),
    images: [
      for (final image in json['images'] as List<dynamic>? ?? const [])
        image as String,
    ],
    external: json['external'] is Map<String, dynamic>
        ? json['external'] as Map<String, dynamic>
        : null,
    source: PersonSource.values.byName(json['source'] as String),
    credits: [
      for (final credit in json['credits'] as List<dynamic>)
        PersonCredit.fromJson(credit as Map<String, dynamic>),
    ],
    stats: PersonStats.fromJson(json['stats'] as Map<String, dynamic>),
  );

  final String id;
  final String slug;
  final String name;
  final int? tmdbId;
  final int? malId;
  final int? anilistId;
  final String? imageUrl;
  final String? biography;
  final String? birthday;
  final String? deathday;
  final String? placeOfBirth;
  final String? knownForDepartment;
  final List<String> alsoKnownAs;
  final int? gender;
  final String? homepage;
  final double? popularity;
  final List<String> images;
  final Map<String, dynamic>? external;
  final PersonSource source;
  final List<PersonCredit> credits;
  final PersonStats stats;
}
