import 'package:flutter/widgets.dart';

import '../l10n/l10n_context.dart';
import '../models/media_type.dart';

const staticGenres = <MediaType, List<String>>{
  MediaType.anime: [
    'Action',
    'Adventure',
    'Comedy',
    'Drama',
    'Fantasy',
    'Horror',
    'Isekai',
    'Mahou Shoujo',
    'Mecha',
    'Music',
    'Mystery',
    'Psychological',
    'Romance',
    'School',
    'Sci-Fi',
    'Shoujo',
    'Shounen',
    'Slice of Life',
    'Sports',
    'Supernatural',
    'Thriller',
  ],
  MediaType.manga: [
    'Action',
    'Adventure',
    'Comedy',
    'Drama',
    'Fantasy',
    'Historical',
    'Horror',
    'Isekai',
    'Josei',
    'Martial Arts',
    'Mecha',
    'Mystery',
    'Romance',
    'School',
    'Sci-Fi',
    'Shoujo',
    'Shounen',
    'Slice of Life',
    'Sports',
    'Supernatural',
    'Thriller',
  ],
  MediaType.book: [
    'Adventure',
    'Biography',
    'Classics',
    'Comics',
    'Crime',
    'Drama',
    'Erotica',
    'Fantasy',
    'Fiction',
    'History',
    'Horror',
    'Mystery',
    'Romance',
    'Science Fiction',
    'Suspense',
    'Thriller',
    'Urban Fantasy',
    'Vampire',
    'War',
    'Western',
    'Young Adult',
  ],
  MediaType.game: [
    'Pinball',
    'Adventure',
    'Indie',
    'Arcade',
    'Visual Novel',
    'Card & Board Game',
    'MOBA',
    'Point-and-click',
    'Fighting',
    'Shooter',
    'Music',
    'Platform',
    'Puzzle',
    'Racing',
    'Real Time Strategy (RTS)',
    'Role-playing (RPG)',
    'Simulator',
    'Sport',
    'Strategy',
    'Turn-based Strategy (TBS)',
    'Tactical',
    'Hack and slash/Beat em up',
    'Quiz/Trivia',
  ],
  MediaType.movie: [
    'Animation',
    'Adventure',
    'TV Movie',
    'Action',
    'Comedy',
    'Drama',
    'Crime',
    'Documentary',
    'Family',
    'Fantasy',
    'Western',
    'War',
    'History',
    'Mystery',
    'Music',
    'Romance',
    'Horror',
    'Science Fiction',
    'Thriller',
  ],
  MediaType.tv: [
    'Action & Adventure',
    'Animation',
    'Comedy',
    'Crime',
    'Documentary',
    'Drama',
    'Family',
    'Kids',
    'Mystery',
    'News',
    'Reality',
    'Sci-Fi & Fantasy',
    'Soap',
    'Talk',
    'War & Politics',
    'Western',
  ],
};

String formatGenreKey(String genreName) {
  final words = genreName.split(' ');
  final buffer = StringBuffer();
  for (var i = 0; i < words.length; i++) {
    final word = words[i];
    if (word.isEmpty) continue;
    if (i == 0) {
      buffer.write(word[0].toLowerCase() + word.substring(1));
    } else {
      buffer.write(word[0].toUpperCase() + word.substring(1));
    }
  }
  return buffer.toString();
}

String genreLabel(BuildContext context, String genreName) {
  final key = 'library:genresList.${formatGenreKey(genreName)}';
  final label = context.t(key);
  return label == key ? genreName : label;
}
