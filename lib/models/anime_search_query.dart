enum AnimeFormat { tv, movie, ova, special, ona, music, cm, pv, tvSpecial }

enum AnimeStatus { airing, complete, upcoming }

enum AnimeOrder { title, startDate, endDate, score, type }

enum AnimeRating { g, pg, pg13, r17, r, rx }

enum SortDirection { asc, desc }

class AnimeSearchQuery {
  AnimeSearchQuery({
    this.query = '',
    this.page = 1,
    this.format,
    this.status,
    this.orderBy,
    this.sort,
    this.rating,
    this.year,
    this.letter,
    this.minTgScore,
    List<String> genres = const [],
  }) : genres = List.unmodifiable(genres) {
    if (page < 1) throw ArgumentError.value(page, 'page');
    if (year != null && (year! < 1000 || year! > 9999)) {
      throw ArgumentError.value(year, 'year');
    }
    if (letter != null && !RegExp(r'^[a-zA-Z]$').hasMatch(letter!)) {
      throw ArgumentError.value(letter, 'letter');
    }
    if (genres.any((genre) => genre.trim().isEmpty || genre.contains(','))) {
      throw ArgumentError.value(genres, 'genres');
    }
    if (minTgScore != null &&
        (!minTgScore!.isFinite || minTgScore! < 0 || minTgScore! > 5)) {
      throw ArgumentError.value(minTgScore, 'minTgScore');
    }
  }

  final String query;
  final int page;
  final AnimeFormat? format;
  final AnimeStatus? status;
  final AnimeOrder? orderBy;
  final SortDirection? sort;
  final AnimeRating? rating;
  final int? year;
  final String? letter;
  final double? minTgScore;
  final List<String> genres;

  Map<String, String> toQueryParameters() => {
    if (query.isNotEmpty) 'query': query,
    if (page > 1) 'page': '$page',
    if (format != null)
      'type': format == AnimeFormat.tvSpecial ? 'tv_special' : format!.name,
    if (status != null) 'status': status!.name,
    if (orderBy != null)
      'orderBy': switch (orderBy!) {
        AnimeOrder.startDate => 'start_date',
        AnimeOrder.endDate => 'end_date',
        final order => order.name,
      },
    if (sort != null) 'sort': sort!.name,
    if (rating != null) 'rating': rating!.name,
    if (year != null) 'year': '$year',
    'letter': ?letter,
    if (minTgScore != null) 'minTgScore': '$minTgScore',
    if (genres.isNotEmpty) 'genres': genres.join(','),
  };
}
