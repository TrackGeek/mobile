import '../models/manga_detail.dart';
import 'social_links.dart';

String _asset(String name) => 'assets/icons/social/$name.svg';

List<PersonLink> mangaExternalLinks(MangaDetail manga) {
  final links = <PersonLink>[];

  PersonLink named(String url, String name, {String asset = ''}) => PersonLink(
    key: 'link-${links.length}',
    href: url,
    asset: asset.isEmpty ? '' : _asset(asset),
    label: name,
  );

  for (final entry in manga.external) {
    final name = entry.name.toLowerCase();
    final url = entry.url;
    if (url.isEmpty) continue;

    if (name.contains('instagram')) {
      links.add(named(url, 'Instagram', asset: 'instagram'));
      continue;
    }
    if (name.contains('facebook')) {
      links.add(named(url, 'Facebook', asset: 'facebook'));
      continue;
    }
    if (name.contains('twitter')) {
      links.add(named(url, 'X', asset: 'x'));
      continue;
    }
    if (name.contains('wikipedia')) {
      links.add(named(url, 'Wikipedia', asset: 'wikipedia'));
      continue;
    }
    final resolved = resolveLink(url);
    links.add(
      PersonLink(
        key: 'link-${links.length}',
        href: url,
        asset: resolved.asset,
        label: entry.name.isEmpty
            ? (resolved.platform ?? resolved.host)
            : entry.name,
      ),
    );
  }

  if (manga.anilistId > 0) {
    links.add(
      PersonLink(
        key: 'anilist',
        href: 'https://anilist.co/manga/${manga.anilistId}',
        asset: _asset('anilist'),
        label: 'AniList',
      ),
    );
  }
  final malId = manga.malId;
  if (malId != null) {
    links.add(
      PersonLink(
        key: 'mal',
        href: 'https://myanimelist.net/manga/$malId',
        asset: _asset('myanimelist'),
        label: 'MyAnimeList',
      ),
    );
  }
  return links;
}
