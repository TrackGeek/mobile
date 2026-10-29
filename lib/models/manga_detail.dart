class MangaTitle {
  const MangaTitle({required this.type, required this.title});

  factory MangaTitle.fromJson(Map<String, dynamic> json) => MangaTitle(
    type: json['type'] as String? ?? '',
    title: json['title'] as String? ?? '',
  );

  final String type;
  final String title;
}

class MangaCast {
  const MangaCast({
    required this.anilistId,
    required this.name,
    this.role,
    this.imageUrl,
  });

  factory MangaCast.fromJson(Map<String, dynamic> json) => MangaCast(
    anilistId: (json['anilistId'] as num?)?.toInt() ?? 0,
    name: json['name'] as String? ?? '',
    role: json['role'] as String?,
    imageUrl: json['imageUrl'] as String?,
  );

  final int anilistId;
  final String name;
  final String? role;
  final String? imageUrl;

  String get label => role == null || role!.isEmpty ? name : '$name ($role)';
}

class MangaCharacter {
  const MangaCharacter({
    required this.anilistId,
    required this.name,
    this.imageUrl,
    this.role,
  });

  factory MangaCharacter.fromJson(Map<String, dynamic> json) => MangaCharacter(
    anilistId: (json['anilistId'] as num?)?.toInt() ?? 0,
    name: json['name'] as String? ?? '',
    imageUrl: json['imageUrl'] as String?,
    role: json['role'] as String?,
  );

  final int anilistId;
  final String name;
  final String? imageUrl;
  final String? role;
}

class MangaExternalLink {
  const MangaExternalLink({required this.name, required this.url});

  factory MangaExternalLink.fromJson(Map<String, dynamic> json) =>
      MangaExternalLink(
        name: json['name'] as String? ?? '',
        url: json['url'] as String? ?? '',
      );

  final String name;
  final String url;
}

class MangaPublished {
  const MangaPublished({this.from, this.to, this.string});

  factory MangaPublished.fromJson(Map<String, dynamic> json) => MangaPublished(
    from: json['from'] as String?,
    to: json['to'] as String?,
    string: json['string'] as String?,
  );

  final String? from;
  final String? to;
  final String? string;
}

class MangaRelationNode {
  const MangaRelationNode({
    required this.id,
    required this.name,
    required this.image,
    required this.link,
    required this.relationShip,
  });

  factory MangaRelationNode.fromJson(Map<String, dynamic> json) =>
      MangaRelationNode(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        image: json['image'] as String? ?? '',
        link: json['link'] as String? ?? '',
        relationShip: json['relationShip'] as String? ?? 'Other',
      );

  final String id;
  final String name;
  final String image;
  final String link;
  final String relationShip;
}

class MangaRelations {
  const MangaRelations({required this.nodes, required this.edges});

  factory MangaRelations.fromJson(Map<String, dynamic> json) => MangaRelations(
    nodes: [
      for (final node in json['nodes'] as List? ?? const [])
        if (node is Map<String, dynamic>) MangaRelationNode.fromJson(node),
    ],
    edges: [
      for (final edge in json['edges'] as List? ?? const [])
        if (edge is Map<String, dynamic>)
          (
            source: edge['source'] as String? ?? '',
            target: edge['target'] as String? ?? '',
          ),
    ],
  );

  final List<MangaRelationNode> nodes;
  final List<({String source, String target})> edges;
}

class MangaStatBucket {
  const MangaStatBucket({required this.count, required this.percentage});

  factory MangaStatBucket.fromJson(Map<String, dynamic> json) =>
      MangaStatBucket(
        count: (json['count'] as num?)?.toInt() ?? 0,
        percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      );

  final int count;
  final double percentage;
}

class MangaProgressStats {
  const MangaProgressStats({
    required this.planning,
    required this.reading,
    required this.completed,
    required this.paused,
    required this.dropped,
  });

  factory MangaProgressStats.fromJson(Map<String, dynamic> json) =>
      MangaProgressStats(
        planning: MangaStatBucket.fromJson(
          json['planning'] as Map<String, dynamic>? ?? const {},
        ),
        reading: MangaStatBucket.fromJson(
          json['reading'] as Map<String, dynamic>? ?? const {},
        ),
        completed: MangaStatBucket.fromJson(
          json['completed'] as Map<String, dynamic>? ?? const {},
        ),
        paused: MangaStatBucket.fromJson(
          json['paused'] as Map<String, dynamic>? ?? const {},
        ),
        dropped: MangaStatBucket.fromJson(
          json['dropped'] as Map<String, dynamic>? ?? const {},
        ),
      );

  final MangaStatBucket planning;
  final MangaStatBucket reading;
  final MangaStatBucket completed;
  final MangaStatBucket paused;
  final MangaStatBucket dropped;
}

class MangaProgress {
  const MangaProgress({
    required this.id,
    required this.status,
    this.chaptersRead,
    this.readCount,
    this.startedAt,
    this.completedAt,
  });

  factory MangaProgress.fromJson(Map<String, dynamic> json) => MangaProgress(
    id: json['id'] as String,
    status: json['status'] as String? ?? '',
    chaptersRead: (json['chaptersRead'] as num?)?.toInt(),
    readCount: (json['readCount'] as num?)?.toInt(),
    startedAt: json['startedAt'] as String?,
    completedAt: json['completedAt'] as String?,
  );

  final String id;
  final String status;
  final int? chaptersRead;
  final int? readCount;
  final String? startedAt;
  final String? completedAt;
}

class MangaDetail {
  const MangaDetail({
    required this.id,
    required this.anilistId,
    this.malId,
    required this.url,
    this.imageUrl,
    this.bannerUrl,
    required this.title,
    required this.titles,
    this.isAdult = false,
    this.anilistScore,
    this.type,
    this.source,
    this.countryOfOrigin,
    this.numberOfChapters,
    this.numberOfVolumes,
    this.status,
    this.published,
    this.popularity,
    this.synopsis,
    required this.authors,
    required this.serializations,
    required this.genres,
    required this.themes,
    required this.demographics,
    this.relations,
    required this.external,
    required this.characters,
    this.lastRefreshedAt,
    this.tgReviewScore = 0,
    this.progressStats,
  });

  factory MangaDetail.fromJson(Map<String, dynamic> json) => MangaDetail(
    id: json['id'] as String,
    anilistId: (json['anilistId'] as num?)?.toInt() ?? 0,
    malId: (json['malId'] as num?)?.toInt(),
    url: json['url'] as String? ?? '',
    imageUrl: json['imageUrl'] as String?,
    bannerUrl: json['bannerUrl'] as String?,
    title: json['title'] as String? ?? '',
    titles: [
      for (final entry in json['titles'] as List? ?? const [])
        if (entry is Map<String, dynamic>) MangaTitle.fromJson(entry),
    ],
    isAdult: json['isAdult'] as bool? ?? false,
    anilistScore: (json['anilistScore'] as num?)?.toDouble(),
    type: json['type'] as String?,
    source: json['source'] as String?,
    countryOfOrigin: json['countryOfOrigin'] as String?,
    numberOfChapters: (json['numberOfChapters'] as num?)?.toInt(),
    numberOfVolumes: (json['numberOfVolumes'] as num?)?.toInt(),
    status: json['status'] as String?,
    published: json['published'] is Map<String, dynamic>
        ? MangaPublished.fromJson(json['published'] as Map<String, dynamic>)
        : null,
    popularity: (json['popularity'] as num?)?.toInt(),
    synopsis: json['synopsis'] as String?,
    authors: [
      for (final entry in json['authors'] as List? ?? const [])
        if (entry is Map<String, dynamic>) MangaCast.fromJson(entry),
    ],
    serializations: [
      for (final entry in json['serializations'] as List? ?? const [])
        if (entry is Map<String, dynamic>) MangaCast.fromJson(entry),
    ],
    genres: [for (final g in json['genres'] as List? ?? const []) '$g'],
    themes: [for (final t in json['themes'] as List? ?? const []) '$t'],
    demographics: [
      for (final d in json['demographics'] as List? ?? const []) '$d',
    ],
    relations: json['relations'] is Map<String, dynamic>
        ? MangaRelations.fromJson(json['relations'] as Map<String, dynamic>)
        : null,
    external: [
      for (final entry in json['external'] as List? ?? const [])
        if (entry is Map<String, dynamic>) MangaExternalLink.fromJson(entry),
    ],
    characters: [
      for (final entry in json['characters'] as List? ?? const [])
        if (entry is Map<String, dynamic>) MangaCharacter.fromJson(entry),
    ],
    lastRefreshedAt: DateTime.tryParse('${json['lastRefreshedAt'] ?? ''}'),
    tgReviewScore: (json['tgReviewScore'] as num?)?.toDouble() ?? 0,
    progressStats: json['progressStats'] is Map<String, dynamic>
        ? MangaProgressStats.fromJson(
            json['progressStats'] as Map<String, dynamic>,
          )
        : null,
  );

  final String id;
  final int anilistId;
  final int? malId;
  final String url;
  final String? imageUrl;
  final String? bannerUrl;
  final String title;
  final List<MangaTitle> titles;
  final bool isAdult;
  final double? anilistScore;
  final String? type;
  final String? source;
  final String? countryOfOrigin;
  final int? numberOfChapters;
  final int? numberOfVolumes;
  final String? status;
  final MangaPublished? published;
  final int? popularity;
  final String? synopsis;
  final List<MangaCast> authors;
  final List<MangaCast> serializations;
  final List<String> genres;
  final List<String> themes;
  final List<String> demographics;
  final MangaRelations? relations;
  final List<MangaExternalLink> external;
  final List<MangaCharacter> characters;
  final DateTime? lastRefreshedAt;
  final double tgReviewScore;
  final MangaProgressStats? progressStats;

  List<MangaTitle> get alternativeTitles {
    final seen = <String>{title.trim().toLowerCase()};
    return [
      for (final entry in titles)
        if (entry.title.trim().isNotEmpty &&
            seen.add(entry.title.trim().toLowerCase()))
          entry,
    ];
  }

  List<MangaCast> get cast => [...authors, ...serializations];
}
