enum MediaType {
  movie,
  tv,
  game,
  anime,
  manga,
  book;

  String get slug => name;

  String get searchEnvelope => switch (this) {
    MediaType.movie => 'movies',
    MediaType.tv => 'tvShows',
    MediaType.game => 'games',
    MediaType.anime => 'animes',
    MediaType.manga => 'mangas',
    MediaType.book => 'books',
  };

  String get detailEnvelope => switch (this) {
    MediaType.tv => 'tvShow',
    _ => name,
  };
}
