import 'anime_detail.dart' show ProgressStat;

String? bookCoverOf(Object? imageUrl) {
  if (imageUrl is String) return imageUrl.isEmpty ? null : imageUrl;
  if (imageUrl is Map<String, dynamic>) {
    final url = imageUrl['url'];
    if (url is String && url.isNotEmpty) return url;
  }
  return null;
}

class BookContribution {
  const BookContribution({this.contribution, required this.author});

  final String? contribution;
  final BookAuthor author;

  factory BookContribution.fromJson(Map<String, dynamic> json) =>
      BookContribution(
        contribution: json['contribution'] as String?,
        author: BookAuthor.fromJson(
          json['author'] is Map<String, dynamic>
              ? json['author'] as Map<String, dynamic>
              : const {},
        ),
      );
}

class BookAuthor {
  const BookAuthor({required this.id, required this.name, this.imageUrl});

  final int id;
  final String name;
  final String? imageUrl;

  factory BookAuthor.fromJson(Map<String, dynamic> json) => BookAuthor(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: '${json['name'] ?? ''}',
    imageUrl: json['imageUrl'] as String?,
  );
}

class BookSeriesEntry {
  const BookSeriesEntry({
    required this.id,
    this.position,
    this.featured = false,
    required this.series,
  });

  final int id;
  final double? position;
  final bool featured;
  final BookSeries series;

  factory BookSeriesEntry.fromJson(Map<String, dynamic> json) =>
      BookSeriesEntry(
        id: (json['id'] as num?)?.toInt() ?? 0,
        position: (json['position'] as num?)?.toDouble(),
        featured: json['featured'] == true,
        series: BookSeries.fromJson(
          json['series'] is Map<String, dynamic>
              ? json['series'] as Map<String, dynamic>
              : const {},
        ),
      );

  String get positionLabel {
    final value = position;
    if (value == null) return '';
    return value == value.roundToDouble() ? '${value.toInt()}' : '$value';
  }
}

class BookSeries {
  const BookSeries({required this.id, required this.name});

  final int id;
  final String name;

  factory BookSeries.fromJson(Map<String, dynamic> json) => BookSeries(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: '${json['name'] ?? ''}',
  );
}

class BookEdition {
  const BookEdition({
    required this.id,
    this.title,
    this.imageUrl,
    this.language,
    this.publisher,
    this.numberOfPages,
    this.isbn10,
    this.isbn13,
    this.releaseYear,
    this.releaseDate,
    this.editionFormat,
  });

  final int id;
  final String? title;
  final String? imageUrl;
  final String? language;
  final String? publisher;
  final int? numberOfPages;
  final String? isbn10;
  final String? isbn13;
  final int? releaseYear;
  final String? releaseDate;
  final String? editionFormat;

  factory BookEdition.fromJson(Map<String, dynamic> json) => BookEdition(
    id: (json['id'] as num?)?.toInt() ?? 0,
    title: json['title'] as String?,
    imageUrl: bookCoverOf(json['imageUrl']),
    language: json['language'] as String?,
    publisher: json['publisher'] as String?,
    numberOfPages: (json['numberOfPages'] as num?)?.toInt(),
    isbn10: json['isbn10']?.toString(),
    isbn13: json['isbn13']?.toString(),
    releaseYear: (json['releaseYear'] as num?)?.toInt(),
    releaseDate: json['releaseDate']?.toString(),
    editionFormat: json['editionFormat'] as String?,
  );
}

class BookProgressStats {
  const BookProgressStats({
    required this.planToRead,
    required this.reading,
    required this.completed,
    required this.dropped,
  });

  final ProgressStat planToRead;
  final ProgressStat reading;
  final ProgressStat completed;
  final ProgressStat dropped;

  factory BookProgressStats.fromJson(
    Map<String, dynamic>? json,
  ) => BookProgressStats(
    planToRead: ProgressStat.fromJson(
      json?['planToRead'] as Map<String, dynamic>?,
    ),
    reading: ProgressStat.fromJson(json?['reading'] as Map<String, dynamic>?),
    completed: ProgressStat.fromJson(
      json?['completed'] as Map<String, dynamic>?,
    ),
    dropped: ProgressStat.fromJson(json?['dropped'] as Map<String, dynamic>?),
  );
}

class BookDetail {
  const BookDetail({
    required this.id,
    required this.hardcoverId,
    required this.slug,
    required this.title,
    this.subtitle,
    this.description,
    this.imageUrl,
    this.releaseDate,
    this.releaseYear,
    this.numberOfPages,
    this.tgReviewScore = 0,
    this.contributions = const [],
    this.taggings = const [],
    this.editions = const [],
    this.defaultPhysicalEdition,
    this.bookSeries = const [],
    this.category,
    this.editionsCount,
    this.coverEditionId,
    this.customCoverEditionId,
    this.lastRefreshedAt,
    this.progressStats,
  });

  final String id;
  final int hardcoverId;
  final String slug;
  final String title;
  final String? subtitle;
  final String? description;
  final String? imageUrl;
  final String? releaseDate;
  final int? releaseYear;
  final int? numberOfPages;
  final double tgReviewScore;
  final List<BookContribution> contributions;
  final List<String> taggings;
  final List<BookEdition> editions;
  final BookEdition? defaultPhysicalEdition;
  final List<BookSeriesEntry> bookSeries;
  final String? category;
  final int? editionsCount;
  final int? coverEditionId;
  final int? customCoverEditionId;
  final DateTime? lastRefreshedAt;
  final BookProgressStats? progressStats;

  factory BookDetail.fromJson(Map<String, dynamic> json) => BookDetail(
    id: '${json['id']}',
    hardcoverId: (json['hardcoverId'] as num?)?.toInt() ?? 0,
    slug: '${json['slug'] ?? ''}',
    title: '${json['title'] ?? ''}',
    subtitle: json['subtitle'] as String?,
    description: json['description'] as String?,
    imageUrl: bookCoverOf(json['imageUrl']),
    releaseDate: json['releaseDate']?.toString(),
    releaseYear: (json['releaseYear'] as num?)?.toInt(),
    numberOfPages: (json['numberOfPages'] as num?)?.toInt(),
    tgReviewScore: (json['tgReviewScore'] as num?)?.toDouble() ?? 0,
    contributions: [
      for (final c in json['contributions'] as List? ?? const [])
        if (c is Map<String, dynamic>) BookContribution.fromJson(c),
    ],
    taggings: [
      for (final t in json['taggings'] as List? ?? const [])
        if (t is Map<String, dynamic> && t['tag'] != null) '${t['tag']}',
    ],
    editions: [
      for (final e in json['editions'] as List? ?? const [])
        if (e is Map<String, dynamic>) BookEdition.fromJson(e),
    ],
    defaultPhysicalEdition:
        json['defaultPhysicalEdition'] is Map<String, dynamic>
        ? BookEdition.fromJson(
            json['defaultPhysicalEdition'] as Map<String, dynamic>,
          )
        : null,
    bookSeries: [
      for (final s in json['bookSeries'] as List? ?? const [])
        if (s is Map<String, dynamic>) BookSeriesEntry.fromJson(s),
    ],
    category: json['bookCategory'] is Map<String, dynamic>
        ? (json['bookCategory'] as Map)['name'] as String?
        : null,
    editionsCount: (json['editionsCount'] as num?)?.toInt(),
    coverEditionId: (json['coverEditionId'] as num?)?.toInt(),
    customCoverEditionId: (json['customCoverEditionId'] as num?)?.toInt(),
    lastRefreshedAt: DateTime.tryParse('${json['lastRefreshedAt'] ?? ''}'),
    progressStats: json['progressStats'] is Map<String, dynamic>
        ? BookProgressStats.fromJson(
            json['progressStats'] as Map<String, dynamic>,
          )
        : null,
  );

  List<String> get authors => [
    for (final contribution in contributions)
      if (contribution.author.name.isNotEmpty) contribution.author.name,
  ];

  BookEdition? get primaryEdition =>
      defaultPhysicalEdition ?? (editions.isEmpty ? null : editions.first);
}

class BookProgress {
  const BookProgress({
    required this.id,
    required this.status,
    this.chaptersRead,
    this.totalPages,
    this.readCount,
    this.startedAt,
    this.completedAt,
  });

  final String id;
  final String status;
  final int? chaptersRead;
  final int? totalPages;
  final int? readCount;
  final String? startedAt;
  final String? completedAt;

  factory BookProgress.fromJson(Map<String, dynamic> json) => BookProgress(
    id: '${json['id']}',
    status: '${json['status'] ?? ''}',
    chaptersRead: (json['chaptersRead'] as num?)?.toInt(),
    totalPages: (json['totalPages'] as num?)?.toInt(),
    readCount: (json['readCount'] as num?)?.toInt(),
    startedAt: json['startedAt'] as String?,
    completedAt: json['completedAt'] as String?,
  );
}

class FranchiseBook {
  const FranchiseBook({
    required this.hardcoverId,
    this.position,
    required this.title,
    this.imageUrl,
    this.releaseYear,
    this.tgReviewScore = 0,
  });

  final int hardcoverId;
  final double? position;
  final String title;
  final String? imageUrl;
  final int? releaseYear;
  final double tgReviewScore;

  factory FranchiseBook.fromJson(Map<String, dynamic> json) => FranchiseBook(
    hardcoverId: (json['hardcoverId'] as num?)?.toInt() ?? 0,
    position: (json['position'] as num?)?.toDouble(),
    title: '${json['title'] ?? ''}',
    imageUrl: bookCoverOf(json['imageUrl']),
    releaseYear: (json['releaseYear'] as num?)?.toInt(),
    tgReviewScore: (json['tgReviewScore'] as num?)?.toDouble() ?? 0,
  );
}

class BookFranchise {
  const BookFranchise({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.imageUrl,
    this.isCompleted = false,
    this.books = const [],
  });

  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? imageUrl;
  final bool isCompleted;
  final List<FranchiseBook> books;

  factory BookFranchise.fromJson(Map<String, dynamic> json) => BookFranchise(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: '${json['name'] ?? ''}',
    slug: '${json['slug'] ?? ''}',
    description: json['description'] as String?,
    imageUrl: bookCoverOf(json['imageUrl']),
    isCompleted: json['isCompleted'] == true,
    books: [
      for (final b in json['books'] as List? ?? const [])
        if (b is Map<String, dynamic>) FranchiseBook.fromJson(b),
    ],
  );
}
