import 'anime_detail.dart' show ProgressStat;

class GameCompany {
  const GameCompany({
    this.companyId,
    required this.name,
    this.developer = false,
    this.publisher = false,
  });

  final int? companyId;
  final String name;
  final bool developer;
  final bool publisher;

  factory GameCompany.fromJson(Map<String, dynamic> json) => GameCompany(
    companyId: (json['companyId'] as num?)?.toInt(),
    name: '${json['companyName'] ?? ''}',
    developer: json['developer'] == true,
    publisher: json['publisher'] == true,
  );
}

class GamePlatform {
  const GamePlatform({required this.name, required this.slug});

  final String name;
  final String slug;

  factory GamePlatform.fromJson(Map<String, dynamic> json) => GamePlatform(
    name: '${json['name'] ?? ''}',
    slug: '${json['slug'] ?? ''}',
  );
}

class GameWebsite {
  const GameWebsite({required this.name, required this.url});

  final String name;
  final String url;

  factory GameWebsite.fromJson(Map<String, dynamic> json) =>
      GameWebsite(name: '${json['name'] ?? ''}', url: '${json['url'] ?? ''}');
}

class GameVideo {
  const GameVideo({
    required this.checksum,
    required this.name,
    required this.videoId,
  });

  final String checksum;
  final String name;
  final String videoId;

  factory GameVideo.fromJson(Map<String, dynamic> json) => GameVideo(
    checksum: '${json['checksum'] ?? ''}',
    name: '${json['name'] ?? ''}',
    videoId: '${json['videoId'] ?? ''}',
  );
}

class GameScreenshotRef {
  const GameScreenshotRef({required this.checksum, required this.imageUrl});

  final String checksum;
  final String imageUrl;

  factory GameScreenshotRef.fromJson(Map<String, dynamic> json) =>
      GameScreenshotRef(
        checksum: '${json['checksum'] ?? ''}',
        imageUrl: '${json['imageId'] ?? ''}',
      );
}

class GameFranchiseRef {
  const GameFranchiseRef({required this.id, required this.name, this.slug});

  final int id;
  final String name;
  final String? slug;

  factory GameFranchiseRef.fromJson(Map<String, dynamic> json) =>
      GameFranchiseRef(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: '${json['name'] ?? ''}',
        slug: json['slug'] as String?,
      );
}

class RelatedGame {
  const RelatedGame({required this.id, required this.name, this.coverUrl});

  final int id;
  final String name;
  final String? coverUrl;

  factory RelatedGame.fromJson(Map<String, dynamic> json) => RelatedGame(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: '${json['name'] ?? ''}',
    coverUrl: json['coverUrl'] as String?,
  );
}

class GameProgressStats {
  const GameProgressStats({
    required this.planToPlay,
    required this.playing,
    required this.completed,
    required this.dropped,
  });

  final ProgressStat planToPlay;
  final ProgressStat playing;
  final ProgressStat completed;
  final ProgressStat dropped;

  factory GameProgressStats.fromJson(
    Map<String, dynamic>? json,
  ) => GameProgressStats(
    planToPlay: ProgressStat.fromJson(
      json?['planToPlay'] as Map<String, dynamic>?,
    ),
    playing: ProgressStat.fromJson(json?['playing'] as Map<String, dynamic>?),
    completed: ProgressStat.fromJson(
      json?['completed'] as Map<String, dynamic>?,
    ),
    dropped: ProgressStat.fromJson(json?['dropped'] as Map<String, dynamic>?),
  );
}

class GameDetail {
  const GameDetail({
    required this.id,
    required this.igdbId,
    required this.slug,
    required this.name,
    this.coverUrl,
    this.summary,
    this.storyline,
    this.firstReleaseDate,
    this.gameStatus,
    this.tgReviewScore = 0,
    this.genres = const [],
    this.themes = const [],
    this.platforms = const [],
    this.gameModes = const [],
    this.playerPerspectives = const [],
    this.gameEngines = const [],
    this.involvedCompanies = const [],
    this.websites = const [],
    this.videos = const [],
    this.screenshots = const [],
    this.franchises = const [],
    this.parentGame,
    this.prequels = const [],
    this.expandedGames = const [],
    this.sequels = const [],
    this.dlcs = const [],
    this.expansions = const [],
    this.ports = const [],
    this.remakes = const [],
    this.remasters = const [],
    this.bundles = const [],
    this.lastRefreshedAt,
    this.progressStats,
  });

  final String id;
  final int igdbId;
  final String slug;
  final String name;
  final String? coverUrl;
  final String? summary;
  final String? storyline;
  final String? firstReleaseDate;
  final String? gameStatus;
  final double tgReviewScore;
  final List<String> genres;
  final List<String> themes;
  final List<GamePlatform> platforms;
  final List<String> gameModes;
  final List<String> playerPerspectives;
  final List<String> gameEngines;
  final List<GameCompany> involvedCompanies;
  final List<GameWebsite> websites;
  final List<GameVideo> videos;
  final List<GameScreenshotRef> screenshots;
  final List<GameFranchiseRef> franchises;
  final RelatedGame? parentGame;
  final List<RelatedGame> prequels;
  final List<RelatedGame> expandedGames;
  final List<RelatedGame> sequels;
  final List<RelatedGame> dlcs;
  final List<RelatedGame> expansions;
  final List<RelatedGame> ports;
  final List<RelatedGame> remakes;
  final List<RelatedGame> remasters;
  final List<RelatedGame> bundles;
  final DateTime? lastRefreshedAt;
  final GameProgressStats? progressStats;

  static List<String> _names(Object? value) => [
    for (final item in value as List? ?? const [])
      if (item is Map<String, dynamic> && item['name'] != null)
        '${item['name']}',
  ];

  static List<RelatedGame> _related(Object? value) => [
    for (final item in value as List? ?? const [])
      if (item is Map<String, dynamic>) RelatedGame.fromJson(item),
  ];

  String? get displayCoverUrl {
    final url = coverUrl;
    if (url == null || url.isEmpty) return null;
    return url.replaceAll('t_cover_big', 't_original');
  }

  List<GameCompany> get developers => [
    for (final c in involvedCompanies)
      if (c.developer) c,
  ];

  List<GameCompany> get publishers => [
    for (final c in involvedCompanies)
      if (c.publisher) c,
  ];

  List<String> get platformNames {
    final names = [for (final p in platforms) p.name];
    names.sort((a, b) {
      if (a == 'PC (Microsoft Windows)') return -1;
      if (b == 'PC (Microsoft Windows)') return 1;
      return 0;
    });
    return names;
  }

  factory GameDetail.fromJson(Map<String, dynamic> json) => GameDetail(
    id: '${json['id']}',
    igdbId: (json['igdbId'] as num?)?.toInt() ?? 0,
    slug: '${json['slug'] ?? ''}',
    name: '${json['name'] ?? ''}',
    coverUrl: json['coverUrl'] as String?,
    summary: json['summary'] as String?,
    storyline: json['storyline'] as String?,
    firstReleaseDate: json['firstReleaseDate']?.toString(),
    gameStatus: json['gameStatus'] as String?,
    tgReviewScore: (json['tgReviewScore'] as num?)?.toDouble() ?? 0,
    genres: _names(json['genres']),
    themes: [for (final t in json['themes'] as List? ?? const []) '$t'],
    platforms: [
      for (final p in json['platforms'] as List? ?? const [])
        if (p is Map<String, dynamic>) GamePlatform.fromJson(p),
    ],
    gameModes: _names(json['gameModes']),
    playerPerspectives: _names(json['playerPerspectives']),
    gameEngines: _names(json['gameEngines']),
    involvedCompanies: [
      for (final c in json['involvedCompanies'] as List? ?? const [])
        if (c is Map<String, dynamic>) GameCompany.fromJson(c),
    ],
    websites: [
      for (final w in json['websites'] as List? ?? const [])
        if (w is Map<String, dynamic>) GameWebsite.fromJson(w),
    ],
    videos: [
      for (final v in json['videos'] as List? ?? const [])
        if (v is Map<String, dynamic>) GameVideo.fromJson(v),
    ],
    screenshots: [
      for (final s in json['screenshots'] as List? ?? const [])
        if (s is Map<String, dynamic>) GameScreenshotRef.fromJson(s),
    ],
    franchises: [
      for (final f in json['franchises'] as List? ?? const [])
        if (f is Map<String, dynamic>) GameFranchiseRef.fromJson(f),
    ],
    parentGame: json['parentGame'] is Map<String, dynamic>
        ? RelatedGame.fromJson(json['parentGame'] as Map<String, dynamic>)
        : null,
    prequels: _related(json['prequels']),
    expandedGames: _related(json['expandedGames']),
    sequels: _related(json['sequels']),
    dlcs: _related(json['dlcs']),
    expansions: _related(json['expansions']),
    ports: _related(json['ports']),
    remakes: _related(json['remakes']),
    remasters: _related(json['remasters']),
    bundles: _related(json['bundles']),
    lastRefreshedAt: DateTime.tryParse('${json['lastRefreshedAt'] ?? ''}'),
    progressStats: json['progressStats'] is Map<String, dynamic>
        ? GameProgressStats.fromJson(
            json['progressStats'] as Map<String, dynamic>,
          )
        : null,
  );
}

class GameProgress {
  const GameProgress({
    required this.id,
    required this.status,
    this.playCount,
    this.completion,
    this.platforms = const [],
    this.hoursPlayed,
    this.notes,
    this.startedAt,
    this.completedAt,
  });

  final String id;
  final String status;
  final int? playCount;
  final String? completion;
  final List<String> platforms;
  final int? hoursPlayed;
  final String? notes;
  final String? startedAt;
  final String? completedAt;

  factory GameProgress.fromJson(Map<String, dynamic> json) => GameProgress(
    id: '${json['id']}',
    status: '${json['status'] ?? ''}',
    playCount: (json['playCount'] as num?)?.toInt(),
    completion: json['completion'] as String?,
    platforms: [for (final p in json['platforms'] as List? ?? const []) '$p'],
    hoursPlayed: (json['hoursPlayed'] as num?)?.toInt(),
    notes: json['notes'] as String?,
    startedAt: json['startedAt'] as String?,
    completedAt: json['completedAt'] as String?,
  );
}

class FranchiseGame {
  const FranchiseGame({
    required this.igdbId,
    required this.name,
    this.coverUrl,
    this.tgReviewScore = 0,
  });

  final int igdbId;
  final String name;
  final String? coverUrl;
  final double tgReviewScore;

  factory FranchiseGame.fromJson(Map<String, dynamic> json) => FranchiseGame(
    igdbId: (json['igdbId'] as num?)?.toInt() ?? 0,
    name: '${json['name'] ?? ''}',
    coverUrl: json['coverUrl'] as String?,
    tgReviewScore: (json['tgReviewScore'] as num?)?.toDouble() ?? 0,
  );
}

class GameFranchise {
  const GameFranchise({
    required this.id,
    required this.name,
    required this.slug,
    this.bannerUrl,
    this.description,
    this.games = const [],
  });

  final int id;
  final String name;
  final String slug;
  final String? bannerUrl;
  final String? description;
  final List<FranchiseGame> games;

  factory GameFranchise.fromJson(Map<String, dynamic> json) => GameFranchise(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: '${json['name'] ?? ''}',
    slug: '${json['slug'] ?? ''}',
    bannerUrl: json['bannerUrl'] as String?,
    description: json['description'] as String?,
    games: [
      for (final g in json['games'] as List? ?? const [])
        if (g is Map<String, dynamic>) FranchiseGame.fromJson(g),
    ],
  );
}
