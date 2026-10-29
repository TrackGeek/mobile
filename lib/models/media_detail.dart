import 'media_type.dart';

class DetailField {
  const DetailField(this.labelKey, this.value);

  final String labelKey;
  final String value;
}

class MediaDetail {
  MediaDetail._({
    required this.type,
    required this.title,
    required this.description,
    required this.isAdult,
    this.imageUrl,
    this.backdropUrl,
    this.score,
    this.tgScore,
    this.altTitle,
    List<String>? chips,
    List<DetailField>? fields,
    this.progressStats,
  }) : chips = List.unmodifiable(chips ?? const []),
       fields = List.unmodifiable(fields ?? const []);

  final MediaType type;
  final String title;
  final String? altTitle;
  final String? imageUrl;
  final String? backdropUrl;
  final double? score;
  final double? tgScore;
  final String? description;
  final bool isAdult;
  final List<String> chips;
  final List<DetailField> fields;
  final Map<String, dynamic>? progressStats;

  static double? _num(Object? v) => (v as num?)?.toDouble();

  static String? _str(Map<String, dynamic>? json, String key) =>
      json?[key] as String?;

  static List<String> _names(Object? value, {String field = 'name'}) =>
      List.unmodifiable(
        (value as List? ?? const [])
            .whereType<Map>()
            .map((item) => item[field] as String?)
            .whereType<String>(),
      );

  static List<String> _strings(Object? value) =>
      List.unmodifiable((value as List? ?? const []).whereType<String>());

  static String? _altTitle(Object? titles) {
    if (titles is! List) return null;
    final others = titles
        .whereType<Map>()
        .where((t) => t['type'] != 'Default' && t['title'] is String)
        .map((t) => t['title'] as String)
        .toSet();
    return others.isEmpty ? null : others.join(' · ');
  }

  static String? _year(Object? iso) {
    if (iso is! String || iso.length < 4) return null;
    return iso.substring(0, 4);
  }

  factory MediaDetail.fromJson(MediaType type, Map<String, dynamic> json) {
    final progress = json['progressStats'];
    return switch (type) {
      MediaType.anime => MediaDetail._(
        type: type,
        title: json['title'] as String,
        altTitle: _altTitle(json['titles']),
        imageUrl: _str(json, 'imageUrl'),
        score: _num(json['malReviewScore']),
        tgScore: _num(json['tgReviewScore']),
        description: _str(json, 'synopsis'),
        isAdult: json['isAdult'] as bool? ?? false,
        chips: [
          ..._strings(json['genres']),
          ..._strings(json['themes']),
          ..._strings(json['demographics']),
        ],
        fields: [
          if (_str(json, 'type') != null)
            DetailField('common:format', _str(json, 'type')!),
          if (_str(json, 'status') != null)
            DetailField('common:status', _str(json, 'status')!),
          if (json['numberOfEpisodes'] != null)
            DetailField('common:episodes', '${json['numberOfEpisodes']}'),
          if (_str(json, 'duration') != null)
            DetailField('common:duration', _str(json, 'duration')!),
          if (_str(json['aired'], 'string') != null)
            DetailField('common:aired', _str(json['aired'], 'string')!),
          if (json['season'] != null || json['year'] != null)
            DetailField(
              'common:season',
              '${json['season'] ?? ''} ${json['year'] ?? ''}'.trim(),
            ),
          if (_str(json, 'source') != null)
            DetailField('common:source', _str(json, 'source')!),
          if (_str(json['broadcast'], 'string') != null)
            DetailField('common:broadcast', _str(json['broadcast'], 'string')!),
          if (_str(json, 'rating') != null)
            DetailField('common:rating', _str(json, 'rating')!),
          if (json['rank'] != null)
            DetailField('common:rank', '#${json['rank']}'),
          if (json['popularity'] != null)
            DetailField('common:popularity', '#${json['popularity']}'),
          ..._names(json['studios'])
              .map((s) => DetailField('common:studio', s)),
        ],
        progressStats: progress is Map<String, dynamic> ? progress : null,
      ),
      MediaType.manga => MediaDetail._(
        type: type,
        title: json['title'] as String,
        altTitle: _altTitle(json['titles']),
        imageUrl: _str(json, 'imageUrl'),
        backdropUrl: _str(json, 'bannerUrl'),
        score: _num(json['anilistScore']),
        tgScore: _num(json['tgReviewScore']),
        description: _str(json, 'synopsis'),
        isAdult: json['isAdult'] as bool? ?? false,
        chips: [
          ..._strings(json['genres']),
          ..._names(json['tags'], field: 'name'),
          ..._strings(json['themes']),
          ..._strings(json['demographics']),
        ],
        fields: [
          if (_str(json, 'type') != null)
            DetailField('common:format', _str(json, 'type')!),
          if (_str(json, 'status') != null)
            DetailField('common:status', _str(json, 'status')!),
          if (json['numberOfChapters'] != null)
            DetailField('common:chapters', '${json['numberOfChapters']}'),
          if (json['numberOfVolumes'] != null)
            DetailField('common:volumes', '${json['numberOfVolumes']}'),
          if (_str(json['published'], 'string') != null)
            DetailField('common:published', _str(json['published'], 'string')!),
          if (_str(json, 'source') != null)
            DetailField('common:source', _str(json, 'source')!),
          if (json['popularity'] != null)
            DetailField('common:popularity', '#${json['popularity']}'),
          ..._names(json['authors'])
              .map((a) => DetailField('common:author', a)),
        ],
        progressStats: progress is Map<String, dynamic> ? progress : null,
      ),
      MediaType.movie => MediaDetail._(
        type: type,
        title: json['title'] as String,
        altTitle: _str(json, 'originalTitle'),
        imageUrl: _str(json, 'posterUrl'),
        backdropUrl: _str(json, 'backdropUrl'),
        score: _num(json['tmdbReviewScore']),
        tgScore: _num(json['tgReviewScore']),
        description: _str(json, 'overview'),
        isAdult: json['isAdult'] as bool? ?? false,
        chips: _names(json['genres']),
        fields: [
          if (_str(json, 'status') != null)
            DetailField('common:status', _str(json, 'status')!),
          if (_year(json['releaseDate']) != null)
            DetailField('common:releaseYear', _year(json['releaseDate'])!),
          if (_str(json, 'releaseDate') != null)
            DetailField('common:releaseDate', _str(json, 'releaseDate')!),
          if (json['runtime'] != null)
            DetailField('common:runtime', '${json['runtime']} min'),
          if (json['popularity'] != null)
            DetailField(
              'common:popularity',
              (json['popularity'] as num).toStringAsFixed(0),
            ),
          ..._names(json['productionCompanies'])
              .map((c) => DetailField('common:company', c)),
        ],
        progressStats: progress is Map<String, dynamic> ? progress : null,
      ),
      MediaType.tv => MediaDetail._(
        type: type,
        title: json['name'] as String,
        altTitle: _str(json, 'originalName'),
        imageUrl: _str(json, 'posterUrl'),
        backdropUrl: _str(json, 'backdropUrl'),
        score: _num(json['tmdbReviewScore']),
        tgScore: _num(json['tgReviewScore']),
        description: _str(json, 'overview') ?? _str(json, 'tagline'),
        isAdult: json['isAdult'] as bool? ?? false,
        chips: _names(json['genres']),
        fields: [
          if (_str(json, 'status') != null)
            DetailField('common:status', _str(json, 'status')!),
          if (_year(json['firstAirDate']) != null)
            DetailField('common:firstAirYear', _year(json['firstAirDate'])!),
          if (_str(json, 'firstAirDate') != null)
            DetailField('common:firstAirDate', _str(json, 'firstAirDate')!),
          if (_str(json, 'lastAirDate') != null)
            DetailField('common:lastAirDate', _str(json, 'lastAirDate')!),
          if (json['numberOfSeasons'] != null)
            DetailField('common:seasons', '${json['numberOfSeasons']}'),
          if (json['numberOfEpisodes'] != null)
            DetailField('common:episodes', '${json['numberOfEpisodes']}'),
          if (json['inProduction'] == true)
            const DetailField('common:inProduction', 'Yes'),
          ..._names(json['networks'])
              .map((n) => DetailField('common:network', n)),
          ..._names(json['createdBy'])
              .map((c) => DetailField('common:creator', c)),
        ],
        progressStats: progress is Map<String, dynamic> ? progress : null,
      ),
      MediaType.game => MediaDetail._(
        type: type,
        title: json['name'] as String,
        imageUrl: _str(json, 'coverUrl'),
        score: _num(json['igdbReviewScore']),
        tgScore: _num(json['tgReviewScore']),
        description: _str(json, 'summary'),
        isAdult: false,
        chips: [..._names(json['genres']), ..._names(json['gameModes'])],
        fields: [
          if (_str(json, 'gameStatus') != null)
            DetailField('common:status', _str(json, 'gameStatus')!),
          if (_year(json['firstReleaseDate']) != null)
            DetailField('common:releaseYear', _year(json['firstReleaseDate'])!),
          if (_str(json, 'firstReleaseDate') != null)
            DetailField('common:releaseDate', _str(json, 'firstReleaseDate')!),
          ..._names(json['platforms'])
              .map((p) => DetailField('common:platform', p)),
          ..._names(
            (json['involvedCompanies'] as List? ?? const [])
                .whereType<Map>()
                .where((c) => c['developer'] == true)
                .toList(),
            field: 'companyName',
          ).map((c) => DetailField('common:developer', c)),
          ..._names(json['franchises'])
              .map((f) => DetailField('common:franchise', f)),
        ],
        progressStats: progress is Map<String, dynamic> ? progress : null,
      ),
      MediaType.book => MediaDetail._(
        type: type,
        title: json['title'] as String,
        imageUrl: _str(json, 'imageUrl'),
        score: _num(json['hardcoverReviewScore']),
        tgScore: _num(json['tgReviewScore']),
        description: _str(json, 'description'),
        isAdult: false,
        chips: [
          ..._names(json['taggings'], field: 'tag'),
          ..._names(json['tags'], field: 'tag'),
        ],
        fields: [
          if (_str(json, 'bookStatus') != null)
            DetailField('common:status', _str(json, 'bookStatus')!),
          if (json['releaseYear'] != null)
            DetailField('common:releaseYear', '${json['releaseYear']}'),
          if (_str(json, 'releaseDate') != null)
            DetailField('common:releaseDate', _str(json, 'releaseDate')!),
          if (json['numberOfPages'] != null)
            DetailField('common:pages', '${json['numberOfPages']}'),
          if (_str(json, 'headline') != null)
            DetailField('common:headline', _str(json, 'headline')!),
          ..._strings(json['contributions'])
              .map((a) => DetailField('common:author', a)),
        ],
        progressStats: progress is Map<String, dynamic> ? progress : null,
      ),
    };
  }
}
