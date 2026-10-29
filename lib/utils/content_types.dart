import '../models/media_type.dart';
import '../services/auth_service.dart';

MediaType? mediaTypeFromApiName(String value) => switch (value) {
  'Movie' => MediaType.movie,
  'TVShow' => MediaType.tv,
  'Game' => MediaType.game,
  'Anime' => MediaType.anime,
  'Manga' => MediaType.manga,
  'Book' => MediaType.book,
  _ => null,
};

Set<MediaType> visibleMediaTypes(SessionUser? user) {
  final stored = user?.contentTypes;
  if (stored == null || stored.isEmpty) return MediaType.values.toSet();
  return {for (final name in stored) ?mediaTypeFromApiName(name)};
}

bool isMediaTypeVisible(SessionUser? user, MediaType type) =>
    visibleMediaTypes(user).contains(type);
