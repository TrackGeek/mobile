import '../models/person.dart';

class ResolvedLink {
  const ResolvedLink({required this.asset, this.platform, required this.host});

  final String asset;
  final String? platform;
  final String host;
}

class PersonLink {
  const PersonLink({
    required this.key,
    required this.href,
    required this.asset,
    required this.label,
  });

  final String key;
  final String href;
  final String asset;
  final String label;
}

String _asset(String name) => 'assets/icons/social/$name.svg';

const _knownHosts = <String, ({String asset, String platform})>{
  'github.com': (asset: 'github', platform: 'GitHub'),
  'gitlab.com': (asset: 'gitlab', platform: 'GitLab'),
  'x.com': (asset: 'x', platform: 'X'),
  'twitter.com': (asset: 'x', platform: 'X'),
  'instagram.com': (asset: 'instagram', platform: 'Instagram'),
  'youtube.com': (asset: 'youtube', platform: 'YouTube'),
  'youtu.be': (asset: 'youtube', platform: 'YouTube'),
  'twitch.tv': (asset: 'twitch', platform: 'Twitch'),
  'kick.com': (asset: 'kick', platform: 'Kick'),
  'tiktok.com': (asset: 'tiktok', platform: 'TikTok'),
  'discord.gg': (asset: 'discord', platform: 'Discord'),
  'discord.com': (asset: 'discord', platform: 'Discord'),
  'linkedin.com': (asset: 'linkedin', platform: 'LinkedIn'),
  'reddit.com': (asset: 'reddit', platform: 'Reddit'),
  'steamcommunity.com': (asset: 'steam', platform: 'Steam'),
  'myanimelist.net': (asset: 'myanimelist', platform: 'MyAnimeList'),
  'anilist.co': (asset: 'anilist', platform: 'AniList'),
  'letterboxd.com': (asset: 'letterboxd', platform: 'Letterboxd'),
  'open.spotify.com': (asset: 'spotify', platform: 'Spotify'),
  'spotify.com': (asset: 'spotify', platform: 'Spotify'),
  'bsky.app': (asset: 'bluesky', platform: 'Bluesky'),
  'threads.net': (asset: 'threads', platform: 'Threads'),
  'threads.com': (asset: 'threads', platform: 'Threads'),
  't.me': (asset: 'telegram', platform: 'Telegram'),
  'telegram.me': (asset: 'telegram', platform: 'Telegram'),
  'mastodon.social': (asset: 'mastodon', platform: 'Mastodon'),
  'behance.net': (asset: 'behance', platform: 'Behance'),
  'dribbble.com': (asset: 'dribbble', platform: 'Dribbble'),
  'medium.com': (asset: 'medium', platform: 'Medium'),
  'dev.to': (asset: 'devdotto', platform: 'DEV'),
  'ko-fi.com': (asset: 'kofi', platform: 'Ko-fi'),
  'patreon.com': (asset: 'patreon', platform: 'Patreon'),
  'wikipedia.org': (asset: 'wikipedia', platform: 'Wikipedia'),
  'wikidata.org': (asset: 'wikidata', platform: 'Wikidata'),
  'crunchbase.com': (asset: 'crunchbase', platform: 'Crunchbase'),
  'facebook.com': (asset: 'facebook', platform: 'Facebook'),
};

ResolvedLink resolveLink(String url) {
  final uri = Uri.tryParse(url);
  final host = uri?.host.toLowerCase().replaceFirst(RegExp('^www\\.'), '');
  if (host == null || host.isEmpty) {
    return ResolvedLink(asset: '', platform: null, host: url);
  }
  final labels = host.split('.');
  for (var i = 0; i < labels.length - 1; i++) {
    final known = _knownHosts[labels.sublist(i).join('.')];
    if (known != null) {
      return ResolvedLink(
        asset: _asset(known.asset),
        platform: known.platform,
        host: host,
      );
    }
  }
  return ResolvedLink(asset: '', platform: null, host: host);
}

String _withBase(String base, String value) =>
    value.startsWith('http') ? value : '$base$value';

String _youtubeHref(String value) {
  if (value.startsWith('http')) return value;
  if (value.contains('/')) return 'https://www.youtube.com/$value';
  if (value.startsWith('UC')) return 'https://www.youtube.com/channel/$value';
  return 'https://www.youtube.com/@${value.replaceFirst(RegExp('^@'), '')}';
}

class _ExternalSpec {
  const _ExternalSpec({
    required this.key,
    required this.fields,
    required this.asset,
    required this.label,
    required this.href,
  });

  final String key;
  final List<String> fields;
  final String asset;
  final String label;
  final String Function(String value) href;
}

List<PersonLink> personExternalLinks(Person person) {
  final external = person.external ?? const <String, dynamic>{};
  final specs = <_ExternalSpec>[
    _ExternalSpec(
      key: 'imdb',
      fields: const ['imdb_id', 'imdb'],
      asset: 'imdb',
      label: 'IMDb',
      href: (v) => _withBase('https://www.imdb.com/name/', v),
    ),
    _ExternalSpec(
      key: 'instagram',
      fields: const ['instagram_id', 'instagram'],
      asset: 'instagram',
      label: 'Instagram',
      href: (v) => _withBase('https://instagram.com/', v),
    ),
    _ExternalSpec(
      key: 'x',
      fields: const ['twitter_id', 'twitter', 'x'],
      asset: 'x',
      label: 'X',
      href: (v) => _withBase('https://twitter.com/', v),
    ),
    _ExternalSpec(
      key: 'facebook',
      fields: const ['facebook_id', 'facebook'],
      asset: 'facebook',
      label: 'Facebook',
      href: (v) => _withBase('https://www.facebook.com/', v),
    ),
    _ExternalSpec(
      key: 'youtube',
      fields: const ['youtube_id', 'youtube'],
      asset: 'youtube',
      label: 'YouTube',
      href: _youtubeHref,
    ),
    _ExternalSpec(
      key: 'tiktok',
      fields: const ['tiktok_id', 'tiktok'],
      asset: 'tiktok',
      label: 'TikTok',
      href: (v) => _withBase('https://www.tiktok.com/@', v),
    ),
    _ExternalSpec(
      key: 'wikipedia',
      fields: const ['wikipedia', 'wikipedia_url'],
      asset: 'wikipedia',
      label: 'Wikipedia',
      href: (v) => _withBase('https://en.wikipedia.org/wiki/', v),
    ),
    _ExternalSpec(
      key: 'wikidata',
      fields: const ['wikidata_id', 'wikidata'],
      asset: 'wikidata',
      label: 'Wikidata',
      href: (v) => _withBase('https://www.wikidata.org/wiki/', v),
    ),
    _ExternalSpec(
      key: 'mal',
      fields: const ['mal'],
      asset: 'myanimelist',
      label: 'MyAnimeList',
      href: (v) => _withBase('https://myanimelist.net/people/', v),
    ),
    _ExternalSpec(
      key: 'anilist',
      fields: const ['anilist'],
      asset: 'anilist',
      label: 'AniList',
      href: (v) => _withBase('https://anilist.co/staff/', v),
    ),
  ];

  final links = <PersonLink>[];
  final consumed = <String>{};

  for (final spec in specs) {
    String? value;
    for (final name in spec.fields) {
      consumed.add(name);
      final raw = external[name];
      if (value == null && ((raw is String && raw.isNotEmpty) || raw is num)) {
        value = '$raw';
      }
    }
    if (value == null) continue;
    links.add(
      PersonLink(
        key: spec.key,
        href: spec.href(value),
        asset: _asset(spec.asset),
        label: spec.label,
      ),
    );
  }

  for (final entry in external.entries) {
    final value = entry.value;
    if (consumed.contains(entry.key) ||
        value is! String ||
        !value.startsWith('http')) {
      continue;
    }
    final resolved = resolveLink(value);
    links.add(
      PersonLink(
        key: entry.key,
        href: value,
        asset: resolved.asset,
        label: resolved.platform ?? resolved.host,
      ),
    );
  }

  final homepage = person.homepage;
  if (homepage != null && homepage.isNotEmpty) {
    links.add(
      PersonLink(key: 'homepage', href: homepage, asset: '', label: homepage),
    );
  }

  return links;
}
