import 'media_type.dart';

class CompanyWork {
  const CompanyWork({
    required this.key,
    required this.id,
    required this.title,
    this.imageUrl,
    this.backdropUrl,
    this.releaseDate,
    this.year,
    this.roles = const [],
    this.isAdult = false,
    this.externalReviewScore,
    this.tgReviewScore = 0,
    this.isTracked = false,
  });

  final String key;
  final int id;
  final String title;
  final String? imageUrl;
  final String? backdropUrl;
  final String? releaseDate;
  final int? year;
  final List<String> roles;
  final bool isAdult;
  final double? externalReviewScore;
  final double tgReviewScore;
  final bool isTracked;

  factory CompanyWork.fromJson(Map<String, dynamic> json) => CompanyWork(
    key: '${json['key'] ?? json['id']}',
    id: (json['id'] as num?)?.toInt() ?? 0,
    title: '${json['title'] ?? ''}',
    imageUrl: json['imageUrl'] as String?,
    backdropUrl: json['backdropUrl'] as String?,
    releaseDate: json['releaseDate'] as String?,
    year: (json['year'] as num?)?.toInt(),
    roles: [for (final r in json['roles'] as List? ?? const []) '$r'],
    isAdult: json['isAdult'] as bool? ?? false,
    externalReviewScore: (json['externalReviewScore'] as num?)?.toDouble(),
    tgReviewScore: (json['tgReviewScore'] as num?)?.toDouble() ?? 0,
    isTracked: json['isTracked'] as bool? ?? false,
  );
}

class CompanyExternalLink {
  const CompanyExternalLink({required this.name, required this.url});

  final String name;
  final String url;

  factory CompanyExternalLink.fromJson(Map<String, dynamic> json) =>
      CompanyExternalLink(
        name: '${json['name'] ?? ''}',
        url: '${json['url'] ?? ''}',
      );
}

class Company {
  const Company({
    required this.id,
    required this.mediaType,
    required this.name,
    this.description,
    this.logoUrl,
    this.bannerUrl,
    this.originCountry,
    this.headquarters,
    this.homepage,
    this.foundedAt,
    this.alsoKnownAs = const [],
    this.external = const [],
    this.works = const [],
    this.totalWorks = 0,
    this.trackedWorks = 0,
  });

  final int id;
  final MediaType mediaType;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? bannerUrl;
  final String? originCountry;
  final String? headquarters;
  final String? homepage;
  final String? foundedAt;
  final List<String> alsoKnownAs;
  final List<CompanyExternalLink> external;
  final List<CompanyWork> works;
  final int totalWorks;
  final int trackedWorks;

  factory Company.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'];
    return Company(
      id: (json['id'] as num?)?.toInt() ?? 0,
      mediaType: switch ('${json['mediaType']}') {
        'movie' => MediaType.movie,
        'tv' => MediaType.tv,
        'game' => MediaType.game,
        _ => MediaType.anime,
      },
      name: '${json['name'] ?? ''}',
      description: json['description'] as String?,
      logoUrl: json['logoUrl'] as String?,
      bannerUrl: json['bannerUrl'] as String?,
      originCountry: json['originCountry'] as String?,
      headquarters: json['headquarters'] as String?,
      homepage: json['homepage'] as String?,
      foundedAt: json['foundedAt'] as String?,
      alsoKnownAs: [
        for (final a in json['alsoKnownAs'] as List? ?? const []) '$a',
      ],
      external: [
        for (final e in json['external'] as List? ?? const [])
          if (e is Map<String, dynamic>) CompanyExternalLink.fromJson(e),
      ],
      works: [
        for (final w in json['works'] as List? ?? const [])
          if (w is Map<String, dynamic>) CompanyWork.fromJson(w),
      ],
      totalWorks: stats is Map<String, dynamic>
          ? (stats['total'] as num?)?.toInt() ?? 0
          : 0,
      trackedWorks: stats is Map<String, dynamic>
          ? (stats['tracked'] as num?)?.toInt() ?? 0
          : 0,
    );
  }

  int? get foundedYear {
    final value = foundedAt;
    if (value == null || value.length < 4) return null;
    return int.tryParse(value.substring(0, 4));
  }
}
