class ParsedVideo {
  const ParsedVideo({
    required this.provider,
    required this.id,
    required this.url,
  });

  final String provider;
  final String id;
  final String url;
}

const _youtubeHosts = [
  'youtube.com',
  'www.youtube.com',
  'm.youtube.com',
  'music.youtube.com',
];
const _youtubeShortHosts = ['youtu.be'];
const _youtubePathPrefixes = ['/embed/', '/shorts/', '/live/', '/v/'];
final _youtubeId = RegExp(r'^[\w-]{11}$');

const _twitchHosts = ['twitch.tv', 'www.twitch.tv', 'm.twitch.tv'];
const _twitchClipHosts = ['clips.twitch.tv'];
final _twitchSlug = RegExp(r'^[\w-]{1,120}$');
final _twitchVideoId = RegExp(r'^\d{1,20}$');

ParsedVideo? _parseYouTube(Uri parsed) {
  final id = _youtubeShortHosts.contains(parsed.host)
      ? parsed.path.substring(1)
      : (parsed.queryParameters['v'] ??
            _youtubePathPrefixes
                .map(
                  (prefix) => parsed.path.startsWith(prefix)
                      ? parsed.path.substring(prefix.length)
                      : null,
                )
                .firstWhere((v) => v != null, orElse: () => null));
  if (id == null || !_youtubeId.hasMatch(id)) return null;
  return ParsedVideo(
    provider: 'YouTube',
    id: id,
    url: 'https://www.youtube.com/watch?v=$id',
  );
}

ParsedVideo? _parseTwitch(Uri parsed) {
  final segments = parsed.pathSegments.where((s) => s.isNotEmpty).toList();

  if (_twitchClipHosts.contains(parsed.host)) {
    final slug = segments.isEmpty ? null : segments.first;
    return slug != null && _twitchSlug.hasMatch(slug)
        ? ParsedVideo(
            provider: 'Twitch',
            id: slug,
            url: 'https://clips.twitch.tv/$slug',
          )
        : null;
  }

  if (segments.isNotEmpty && segments[0] == 'videos') {
    final id = segments.length > 1 ? segments[1] : null;
    return id != null && _twitchVideoId.hasMatch(id)
        ? ParsedVideo(
            provider: 'Twitch',
            id: id,
            url: 'https://www.twitch.tv/videos/$id',
          )
        : null;
  }

  if (segments.length > 2 && segments[1] == 'clip') {
    final slug = segments[2];
    return _twitchSlug.hasMatch(slug)
        ? ParsedVideo(
            provider: 'Twitch',
            id: slug,
            url: 'https://clips.twitch.tv/$slug',
          )
        : null;
  }

  return null;
}

ParsedVideo? parseVideoUrl(String url) {
  final parsed = Uri.tryParse(url.trim());
  if (parsed == null) return null;
  if (parsed.scheme != 'https' && parsed.scheme != 'http') return null;

  if (_youtubeHosts.contains(parsed.host) ||
      _youtubeShortHosts.contains(parsed.host)) {
    return _parseYouTube(parsed);
  }
  if (_twitchHosts.contains(parsed.host) ||
      _twitchClipHosts.contains(parsed.host)) {
    return _parseTwitch(parsed);
  }
  return null;
}

String? videoThumbnailUrl(ParsedVideo video) => video.provider == 'YouTube'
    ? 'https://i.ytimg.com/vi/${video.id}/hqdefault.jpg'
    : null;
