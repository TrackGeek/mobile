import '../models/media_type.dart';
import 'episode_backfill.dart';

const watchLinkMediaTypes = [MediaType.movie, MediaType.tv, MediaType.anime];

const watchLinkContentType = {
  MediaType.movie: 'Movie',
  MediaType.tv: 'TVShow',
  MediaType.anime: 'Anime',
};

const watchLinkMediaTypeFromApi = {
  'Movie': MediaType.movie,
  'TVShow': MediaType.tv,
  'Anime': MediaType.anime,
};

const watchLinkVariables = [
  'ID_IMDB',
  'ID_TMDB',
  'ID_MAL',
  'TITLE',
  'TITLE+',
  'TITLE-',
  'TITLE_ROMANJI',
  'TITLE_ROMANJI+',
  'TITLE_ROMANJI-',
  'SEASON',
  'EPISODE',
];

const _allMediaTypes = watchLinkMediaTypes;

const watchLinkVariableSupport = {
  'ID_IMDB': [MediaType.movie, MediaType.tv],
  'ID_TMDB': [MediaType.movie, MediaType.tv],
  'ID_MAL': [MediaType.anime],
  'TITLE': _allMediaTypes,
  'TITLE+': _allMediaTypes,
  'TITLE-': _allMediaTypes,
  'TITLE_ROMANJI': _allMediaTypes,
  'TITLE_ROMANJI+': _allMediaTypes,
  'TITLE_ROMANJI-': _allMediaTypes,
  'SEASON': [MediaType.tv, MediaType.anime],
  'EPISODE': [MediaType.tv, MediaType.anime],
};

const maxWatchLinks = 20;
const maxWatchLinkUrlLength = 500;

const _blockedSchemes = {
  'javascript',
  'data',
  'vbscript',
  'file',
  'blob',
  'about',
};

final _schemeRegex = RegExp(
  r'^([a-z][a-z0-9+.-]*):/?/?(.+)$',
  caseSensitive: false,
);
final _variableRegex = RegExp(r'%([^%\s]+)%');
final _unsafeChars = RegExp(r'''[\s<>"']''');
final _nonWordChars = RegExp(r'[^\p{L}\p{N}\s-]', unicode: true);
final _nonWordSeparator = RegExp(r'[^\p{L}\p{N}]+', unicode: true);
final _whitespace = RegExp(r'\s+');
final _combiningMarks = RegExp(r'[\u0300-\u036f]');

const _accentMap = {
  'à': 'a',
  'á': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'å': 'a',
  'ā': 'a',
  'ă': 'a',
  'ą': 'a',
  'ç': 'c',
  'ć': 'c',
  'č': 'c',
  'ĉ': 'c',
  'ċ': 'c',
  'ď': 'd',
  'đ': 'd',
  'è': 'e',
  'é': 'e',
  'ê': 'e',
  'ë': 'e',
  'ē': 'e',
  'ĕ': 'e',
  'ė': 'e',
  'ę': 'e',
  'ě': 'e',
  'ĝ': 'g',
  'ğ': 'g',
  'ġ': 'g',
  'ģ': 'g',
  'ĥ': 'h',
  'ħ': 'h',
  'ì': 'i',
  'í': 'i',
  'î': 'i',
  'ï': 'i',
  'ĩ': 'i',
  'ī': 'i',
  'ĭ': 'i',
  'į': 'i',
  'ı': 'i',
  'ĵ': 'j',
  'ķ': 'k',
  'ĺ': 'l',
  'ļ': 'l',
  'ľ': 'l',
  'ŀ': 'l',
  'ł': 'l',
  'ñ': 'n',
  'ń': 'n',
  'ņ': 'n',
  'ň': 'n',
  'ò': 'o',
  'ó': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ø': 'o',
  'ō': 'o',
  'ŏ': 'o',
  'ő': 'o',
  'ŕ': 'r',
  'ŗ': 'r',
  'ř': 'r',
  'ś': 's',
  'ŝ': 's',
  'ş': 's',
  'š': 's',
  'ţ': 't',
  'ť': 't',
  'ŧ': 't',
  'ù': 'u',
  'ú': 'u',
  'û': 'u',
  'ü': 'u',
  'ũ': 'u',
  'ū': 'u',
  'ŭ': 'u',
  'ů': 'u',
  'ű': 'u',
  'ų': 'u',
  'ŵ': 'w',
  'ý': 'y',
  'ÿ': 'y',
  'ŷ': 'y',
  'ź': 'z',
  'ż': 'z',
  'ž': 'z',
  'æ': 'ae',
  'œ': 'oe',
  'ß': 'ss',
  'þ': 'th',
  'ð': 'd',
};

bool isSafeWatchLinkUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty || trimmed.length > maxWatchLinkUrlLength) return false;
  if (_unsafeChars.hasMatch(trimmed)) return false;
  final match = _schemeRegex.firstMatch(trimmed);
  return match != null &&
      !_blockedSchemes.contains(match.group(1)!.toLowerCase());
}

bool isKnownWatchLinkVariable(String name) =>
    watchLinkVariables.contains(name.toUpperCase());

List<String> watchLinkVariablesIn(String template) => [
  for (final m in _variableRegex.allMatches(template))
    m.group(1)!.toUpperCase(),
];

String _normalize(String value) {
  final buffer = StringBuffer();
  for (final char in value.trim().toLowerCase().split('')) {
    buffer.write(_accentMap[char] ?? char);
  }
  return buffer.toString().replaceAll(_combiningMarks, '').trim();
}

String _plainTitle(String value) {
  final normalized = _normalize(value);
  final cleaned = normalized
      .replaceAll(_nonWordChars, ' ')
      .replaceAll(_whitespace, ' ')
      .trim();
  return Uri.encodeComponent(cleaned.isEmpty ? normalized : cleaned);
}

String _joinedTitle(String value, String separator) {
  final normalized = _normalize(value);
  final parts = normalized
      .split(_nonWordSeparator)
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return Uri.encodeComponent(normalized);
  return parts.map(Uri.encodeComponent).join(separator);
}

class WatchLinkContext {
  const WatchLinkContext({
    required this.mediaType,
    this.imdbId,
    this.tmdbId,
    this.malId,
    this.title,
    this.titleRomaji,
    this.season,
    this.episode,
  });

  final MediaType mediaType;
  final String? imdbId;
  final Object? tmdbId;
  final Object? malId;
  final String? title;
  final String? titleRomaji;
  final int? season;
  final int? episode;
}

String? _resolveVariable(String name, WatchLinkContext context) {
  final title = context.title?.trim();
  final romaji = context.titleRomaji?.trim().isNotEmpty == true
      ? context.titleRomaji!.trim()
      : title;
  switch (name) {
    case 'ID_IMDB':
      return context.imdbId?.toString();
    case 'ID_TMDB':
      return context.tmdbId?.toString();
    case 'ID_MAL':
      return context.malId?.toString();
    case 'TITLE':
      return title == null || title.isEmpty ? null : _plainTitle(title);
    case 'TITLE+':
      return title == null || title.isEmpty ? null : _joinedTitle(title, '+');
    case 'TITLE-':
      return title == null || title.isEmpty ? null : _joinedTitle(title, '-');
    case 'TITLE_ROMANJI':
      return romaji == null || romaji.isEmpty ? null : _plainTitle(romaji);
    case 'TITLE_ROMANJI+':
      return romaji == null || romaji.isEmpty
          ? null
          : _joinedTitle(romaji, '+');
    case 'TITLE_ROMANJI-':
      return romaji == null || romaji.isEmpty
          ? null
          : _joinedTitle(romaji, '-');
    case 'SEASON':
      return '${(context.season ?? 0) > 0 ? context.season : 1}';
    case 'EPISODE':
      return '${(context.episode ?? 0) > 0 ? context.episode : 1}';
    default:
      return null;
  }
}

const watchLinkSampleContext = WatchLinkContext(
  mediaType: MediaType.tv,
  imdbId: 'tt0944947',
  tmdbId: 1399,
  malId: 21,
  title: 'Spider-Man: A Brand New Day',
  titleRomaji: 'Kimetsu no Yaiba',
  season: 2,
  episode: 5,
);

String watchLinkVariableExample(String variable) =>
    _resolveVariable(variable.toUpperCase(), watchLinkSampleContext) ?? '';

String previewWatchLinkUrl(String template) => template.trim().replaceAllMapped(
  _variableRegex,
  (m) =>
      _resolveVariable(m.group(1)!.toUpperCase(), watchLinkSampleContext) ??
      m.group(0)!,
);

String? resolveWatchLinkUrl(String template, WatchLinkContext context) {
  var unresolved = false;
  final url = template.trim().replaceAllMapped(_variableRegex, (m) {
    final value = _resolveVariable(m.group(1)!.toUpperCase(), context);
    if (value == null) unresolved = true;
    return value ?? m.group(0)!;
  });
  if (unresolved || !isSafeWatchLinkUrl(url)) return null;
  return url;
}

int nextWatchEpisode(List<int> watchedEpisodes) {
  if (watchedEpisodes.isEmpty) return 1;
  final sorted = watchedEpisodes.toSet().toList()..sort();
  var next = sorted.first;
  for (final episode in sorted) {
    if (episode > next) break;
    next = episode + 1;
  }
  return next;
}

({int season, int episode}) nextEpisodeFromSeasons(
  List<SeasonWatchData> seasons,
) {
  final ordered = [
    for (final s in seasons)
      if (s.seasonNumber > 0) s,
  ]..sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber));
  for (final season in ordered) {
    final watched = season.watchedEpisodes.toSet();
    for (var episode = 1; episode <= season.totalEpisodes; episode++) {
      if (!watched.contains(episode)) {
        return (season: season.seasonNumber, episode: episode);
      }
    }
  }
  if (ordered.isEmpty) return (season: 1, episode: 1);
  final last = ordered.last;
  return (
    season: last.seasonNumber,
    episode: last.totalEpisodes > 1 ? last.totalEpisodes : 1,
  );
}
