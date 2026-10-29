import 'media_type.dart';

enum SearchTarget { media, user, person }

class SearchItem {
  const SearchItem({
    required this.target,
    required this.id,
    required this.title,
    this.mediaType,
    this.imageUrl,
    this.subtitle,
    this.score,
    this.year,
    this.isAdult = false,
    this.username,
    this.dedupKey,
  });

  final SearchTarget target;
  final MediaType? mediaType;
  final String id;
  final String title;
  final String? imageUrl;
  final String? subtitle;
  final double? score;
  final int? year;
  final bool isAdult;
  final String? username;
  final String? dedupKey;

  static String _detailId(Map<String, dynamic> json) =>
      switch (json['anilistId'] ??
      json['malId'] ??
      json['tmdbId'] ??
      json['hardcoverId'] ??
      json['igdbId']) {
        final num id => '$id',
        _ => throw const FormatException('Missing provider ID'),
      };

  static String? _dedupId(Map<String, dynamic> json) => switch (json['malId'] ??
      json['tmdbId'] ??
      json['hardcoverId'] ??
      json['igdbId']) {
    final num id => '$id',
    _ => null,
  };

  factory SearchItem.media(MediaType type, Map<String, dynamic> json) =>
      SearchItem(
        target: SearchTarget.media,
        mediaType: type,
        id: _detailId(json),
        title: (json['title'] ?? json['name']) as String,
        imageUrl:
            (json['imageUrl'] ?? json['coverUrl'] ?? json['posterUrl'])
                as String?,
        subtitle: switch (type) {
          MediaType.game => json['gameStatus'] as String?,
          _ => json['type'] as String? ?? json['status'] as String?,
        },
        score: switch (type) {
          MediaType.anime => (json['malReviewScore'] as num?)?.toDouble(),
          MediaType.manga => (json['anilistScore'] as num?)?.toDouble(),
          MediaType.book => (json['hardcoverReviewScore'] as num?)?.toDouble(),
          MediaType.game => (json['igdbReviewScore'] as num?)?.toDouble(),
          _ => (json['tmdbReviewScore'] as num?)?.toDouble(),
        },
        isAdult: json['isAdult'] as bool? ?? false,
        year: _year(json),
        dedupKey: _dedupId(json),
      );

  static int? _year(Map<String, dynamic> json) {
    for (final key in [
      'airedFrom',
      'releaseDate',
      'firstAirDate',
      'publishedFrom',
      'firstReleaseDate',
      'releaseYear',
    ]) {
      final value = json[key];
      if (value is int) return value;
      if (value is String && value.length >= 4) {
        return int.tryParse(value.substring(0, 4));
      }
    }
    return null;
  }

  factory SearchItem.user(Map<String, dynamic> json) {
    final profile = json['profile'];
    final username = json['username'] as String;
    return SearchItem(
      target: SearchTarget.user,
      id: json['id'] as String,
      title: json['name'] as String? ?? username,
      imageUrl: profile is Map<String, dynamic>
          ? profile['avatarUrl'] as String?
          : null,
      subtitle: '@$username',
      username: username,
    );
  }

  factory SearchItem.person(Map<String, dynamic> json) => SearchItem(
    target: SearchTarget.person,
    id: json['slug'] as String? ?? '${json['tmdbId']}',
    title: json['name'] as String,
    imageUrl: json['imageUrl'] as String?,
    subtitle: json['knownForDepartment'] as String?,
    isAdult: json['isAdult'] as bool? ?? false,
  );
}
