String stripMarkdown(String text) => text
    .replaceAll(RegExp(r'!\[[^\]]*\]\([^)]*\)'), '')
    .replaceAllMapped(
      RegExp(r'\[([^\]]*)\]\([^)]*\)'),
      (match) => match.group(1)!,
    )
    .replaceAll(RegExp(r'[*_~`>#]'), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

const _anilistHosts = {'anilist.co', 'www.anilist.co'};

const _anilistPathMap = {'staff': '/manga/cast', 'manga': '/manga'};

String? internalAnilistPath(String? href) {
  if (href == null || href.isEmpty) return null;
  final url = Uri.tryParse(href);
  if (url == null || !_anilistHosts.contains(url.host)) return null;
  final segments = url.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.length < 2) return null;
  final base = _anilistPathMap[segments[0]];
  final id = segments[1];
  if (base == null || !RegExp(r'^\d+$').hasMatch(id)) return null;
  return '$base/$id';
}
