import 'media_type.dart';

class ProgressItem {
  const ProgressItem({
    required this.type,
    required this.detailId,
    required this.title,
    required this.status,
    this.mediaId,
    this.year,
    this.imageUrl,
    this.current,
    this.total,
    this.nextEpisode,
    this.updatedAt,
    this.completion,
    this.hoursPlayed,
  });

  final MediaType type;
  final String detailId;
  final String title;
  final String status;
  final String? mediaId;
  final int? year;
  final String? imageUrl;
  final int? current;
  final int? total;
  final Map<String, dynamic>? nextEpisode;
  final DateTime? updatedAt;
  final String? completion;
  final double? hoursPlayed;

  bool get canIncrement {
    if (mediaId == null || current == null) return false;
    return switch (type) {
      MediaType.anime || MediaType.tv =>
        const ['Watching', 'Rewatching'].contains(status) &&
            nextEpisode != null,
      MediaType.manga || MediaType.book =>
        const ['Reading', 'Rereading'].contains(status) &&
            (total == null || current! < total!),
      _ => false,
    };
  }

  static const _mediaKey = {
    MediaType.anime: 'anime',
    MediaType.manga: 'manga',
    MediaType.tv: 'tvShow',
    MediaType.movie: 'movie',
    MediaType.game: 'game',
    MediaType.book: 'book',
  };

  factory ProgressItem.fromJson(MediaType type, Map<String, dynamic> json) {
    final media = json[_mediaKey[type]];
    if (media is! Map<String, dynamic>) {
      throw const FormatException('Missing media on progress item');
    }
    final id = switch (type) {
      MediaType.anime => media['malId'],
      MediaType.manga => media['anilistId'] ?? media['malId'],
      MediaType.tv || MediaType.movie => media['tmdbId'],
      MediaType.book => media['hardcoverId'],
      MediaType.game => media['igdbId'],
    };
    final episodeProgress = json['episodeProgress'];
    final reading = type == MediaType.manga || type == MediaType.book;
    final current = reading
        ? (json['chaptersRead'] as num?)?.toInt() ?? 0
        : episodeProgress is Map<String, dynamic>
        ? (episodeProgress['current'] as num?)?.toInt()
        : null;
    final rawTotal = reading
        ? type == MediaType.book
              ? json['totalPages'] ?? media['numberOfPages']
              : media['numberOfChapters']
        : episodeProgress is Map<String, dynamic>
        ? episodeProgress['total']
        : null;
    final total = (rawTotal as num?)?.toInt();
    final date = media['firstAirDate'] ?? media['releaseDate'];
    return ProgressItem(
      type: type,
      detailId: '$id',
      mediaId: media['id'] as String?,
      year:
          (media['year'] as num?)?.toInt() ??
          (date is String ? DateTime.tryParse(date)?.year : null),
      title: (media['title'] ?? media['name']) as String,
      status: json['status'] as String? ?? '',
      imageUrl:
          (media['imageUrl'] ?? media['coverUrl'] ?? media['posterUrl'])
              as String?,
      current: current,
      total: total != null && total > 0 ? total : null,
      nextEpisode: episodeProgress is Map<String, dynamic>
          ? episodeProgress['next'] as Map<String, dynamic>?
          : null,
      updatedAt: DateTime.tryParse('${json['updatedAt']}'),
      completion: json['completion'] as String?,
      hoursPlayed: (json['hoursPlayed'] as num?)?.toDouble(),
    );
  }
}
