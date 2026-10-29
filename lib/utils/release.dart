import '../models/media_type.dart';

const _unreleasedStatuses = <MediaType, List<String>>{
  MediaType.anime: ['Not yet aired'],
  MediaType.manga: ['Not yet published'],
  MediaType.tv: ['Planned', 'In Production', 'Pilot'],
  MediaType.movie: ['Planned', 'In Production', 'Post Production', 'Rumored'],
  MediaType.game: ['Not Released', 'Rumored'],
  MediaType.book: [],
};

bool isMediaUnreleased(
  MediaType type, {
  String? status,
  String? releaseDate,
  int? releaseYear,
}) {
  if (type == MediaType.book) {
    if (releaseDate != null) {
      final date = DateTime.tryParse(releaseDate);
      if (date != null) return date.isAfter(DateTime.now());
    }
    if (releaseYear != null) return releaseYear > DateTime.now().year;
    return false;
  }
  return status == null ||
      (_unreleasedStatuses[type]?.contains(status) ?? false);
}
