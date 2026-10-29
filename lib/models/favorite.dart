import '../services/favorite_service.dart';
import 'media_type.dart';

class Favorite {
  const Favorite({required this.id, required this.type, required this.media});

  final String id;
  final String type;
  final Map<String, dynamic>? media;

  factory Favorite.fromJson(Map<String, dynamic> json) {
    const keys = [
      'anime',
      'manga',
      'tvShow',
      'movie',
      'game',
      'book',
      'person',
    ];
    Map<String, dynamic>? media;
    for (final key in keys) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        media = value;
        break;
      }
    }
    return Favorite(
      id: '${json['id']}',
      type: '${json['type'] ?? ''}',
      media: media,
    );
  }
}

class FavoriteItem {
  const FavoriteItem({
    required this.id,
    required this.title,
    required this.image,
    required this.target,
    required this.slug,
    required this.mediaId,
    this.contentType,
  });

  final String id;
  final String title;
  final String image;
  final FavoriteTarget target;
  final String slug;
  final String mediaId;
  final MediaType? contentType;
}

FavoriteItem? favoriteToItem(Favorite favorite) {
  final media = favorite.media;
  if (media == null) return null;

  String? slugOf(List<String> keys) {
    for (final key in keys) {
      final value = media[key];
      if (value != null) return '$value';
    }
    return null;
  }

  FavoriteItem? build(
    FavoriteTarget target,
    String slug,
    String titleKey,
    String imageKey, [
    MediaType? contentType,
  ]) => FavoriteItem(
    id: favorite.id,
    title: '${media[titleKey] ?? ''}',
    image: '${media[imageKey] ?? ''}',
    target: target,
    slug: slug,
    mediaId: '${media['id'] ?? ''}',
    contentType: contentType,
  );

  return switch (favorite.type) {
    'Anime' =>
      slugOf(const ['malId']) == null
          ? null
          : build(
              FavoriteTarget.anime,
              slugOf(const ['malId'])!,
              'title',
              'imageUrl',
              MediaType.anime,
            ),
    'Manga' =>
      slugOf(const ['anilistId', 'malId']) == null
          ? null
          : build(
              FavoriteTarget.manga,
              slugOf(const ['anilistId', 'malId'])!,
              'title',
              'imageUrl',
              MediaType.manga,
            ),
    'TVShow' =>
      slugOf(const ['tmdbId']) == null
          ? null
          : build(
              FavoriteTarget.tv,
              slugOf(const ['tmdbId'])!,
              'name',
              'posterUrl',
              MediaType.tv,
            ),
    'Movie' =>
      slugOf(const ['tmdbId']) == null
          ? null
          : build(
              FavoriteTarget.movie,
              slugOf(const ['tmdbId'])!,
              'title',
              'posterUrl',
              MediaType.movie,
            ),
    'Game' =>
      slugOf(const ['igdbId']) == null
          ? null
          : build(
              FavoriteTarget.game,
              slugOf(const ['igdbId'])!,
              'name',
              'coverUrl',
              MediaType.game,
            ),
    'Book' =>
      slugOf(const ['hardcoverId']) == null
          ? null
          : build(
              FavoriteTarget.book,
              slugOf(const ['hardcoverId'])!,
              'title',
              'imageUrl',
              MediaType.book,
            ),
    'Person' =>
      slugOf(const ['slug']) == null
          ? null
          : build(
              FavoriteTarget.person,
              slugOf(const ['slug'])!,
              'name',
              'imageUrl',
            ),
    _ => null,
  };
}
